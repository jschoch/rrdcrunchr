require 'rubygems'
require 'gchart'

def get_hosts
  # probly want to do this at init
  
  paths = Dir[CONF['rrd_data_home']+"/*"].sort
  #hosts = {}
  hosts = ["All"]
  #count = 0
  for path in paths
    p = path.split("/")
    #hosts[p[-1]] = count
    #count = count +1
    hosts.push(p[-1])
    puts "hosts found: #{p[-1]}"
  end
  
  hosts
end
def get_rrdtypes
  puts "Searching for RRD Types"
  paths = Dir[CONF['rrd_data_home']+"/**/*.rrd"].sort
  rrdtypes = ["All"]
  dir_exclude = CONF['dir_exclude'].split(" ")
  for path in paths
    p = path.split("/")
    if (rrdtypes.include?(p[-1]))
      print "."
    else
      rrdtypes.push(p[-1]) unless dir_exclude.include?(p[-2])
      print "*"
    end
  end
  rrdtypes
end

def median (array, already_sorted=false)
  return nil if array.empty?
  array = array.sort unless already_sorted
  m_pos = array.size / 2
  return array.size % 2 == 1 ? array[m_pos] : mean (array[m_pos-1..m_pos])
end
def mean(array)
  array.inject(0) { |sum, x| sum +=x } /array.size.to_f
end

def get_rrd(interval,rrd_file,rrd_type,resolution)
  time = Time.now
  start_time = ((time.tv_sec/resolution.to_i)*resolution.to_i)
  puts "#{CONF['rrdtool_path']}/rrdtool fetch #{rrd_file} #{rrd_type} -e #{start_time} -r #{resolution} -s e-#{interval}m |#{CONF['awk_path']}/awk '{printf\"%s,\", $2}'"
  rawdata = `#{CONF['rrdtool_path']}/rrdtool fetch #{rrd_file} #{rrd_type} -e #{start_time} -r #{resolution} -s e-#{interval}m |#{CONF['awk_path']}/awk '{printf"%s,", $2}'` 
  datas = rawdata.split(",")
  mdata = []
  ymax =0
  ymin = 100000000
  for d in datas
        #STDOUT.print "#{d} " unless  d.downcase =~ /nan/
        stat = d.to_f
        if (stat)
                mdata.push(stat) unless d.downcase =~ /nan/
        end
        if (ymax < stat)
                ymax = d.to_f
        end
        if (ymin > stat)
                ymin = d.to_f
        end
  end
  is_zero = false
  stat_median = median(mdata)
  if (stat_median == 0 and ymin.to_f == 0 && ymax.to_f == 0)
        is_zero = true
  end
  [mdata,is_zero,ymin,ymax,stat_median]
end


def get_uri(rrd_file,interval,resolution,host)

  # check exclude list
  #

  names = rrd_file.split("\/")
  source = "http://chart.apis.google.com/chart"
  type = "ls"
  colour = "8198A2"
  threshold_colour = "ff0000"

  is_zero = false
  min_data,is_zero,ymin,ymax,stat_median = get_rrd(interval,rrd_file,"MIN",resolution)
  max_data,is_zero,ymin,ymax,stat_median = get_rrd(interval,rrd_file,"MAX",resolution)
  avg_data,is_zero,ymin,ymax,stat_median = get_rrd(interval,rrd_file,"AVERAGE",resolution)

  
  # 80th percentile stuff, not needed right now

  
  all_data = []

  if (min_data == avg_data && max_data == avg_data)
  all_data = avg_data
  else
  all_data = [min_data,max_data,avg_data]
  end
  # :line_colors => 'FF0000,00FF00,666666',
  uri = Gchart.line( :size => '1000x165', 
      :title => "#{host} #{names[-1]}",
      :bg => 'FFCCFF',
      :line_colors => 'FF0000,00FF00,666666',
      :axis_with_labels => ['x','y','r'],
      :encoding => 'simple',
      :data => all_data)

  names = rrd_file.split("\/")
  [uri,names[-1],ymin,ymax,stat_median,is_zero]
end

def draw_table(img_src,counter_name,ymin,ymax,stat_median,dir_name)
  template = ERB.new <<-EOF
<center>
<table id=result border=0><tr>
  <td id=counter><%= counter_name %></td>
  <td rowspan=2 id=sparkline>
  <img src=<%=img_src%>></a></td>
  <td rowspan=2>
  <div id=max><%= ymax.to_f %></div>
        <div id=med><%= stat_median %></div>
        <div id=min><%= ymin.to_f %></div></td><td rowspan=2>put my description here</td>
</tr>
<tr>
<td id=filter><%= dir_name %></td>
</tr>
</table></center>

  EOF
  template.result(binding)
  

  end