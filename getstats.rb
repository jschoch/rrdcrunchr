if __FILE__ == $0
  # TODO Generated stub
  require 'rubygems'
  require 'hpricot'
  require 'erb' 
  require 'yaml'
  require 'gchart'

  CONF = YAML.load_file("./rcr.yaml")


  #unless ARGV[0] interval = 10
  interval = 10 unless ARGV[0] 
  
  STDOUT.puts "using interval #{interval}"
  STDOUT.puts "RRD Data: #{CONF['rrd_data_path']}"
  dir_exclude = CONF['dir_exclude'].split(" ")


  #
  ## find median from ruby cookbook
  #
  

 def median (array, already_sorted=false)
  return nil if array.empty?
  array = array.sort unless already_sorted
  m_pos = array.size / 2
  return array.size % 2 == 1 ? array[m_pos] : mean (array[m_pos-1..m_pos])
 end
 def mean(array)
 	array.inject(0) { |sum, x| sum +=x } /array.size.to_f
 end
  #
  # chart setup
  #

 def get_uri(rrd_file,interval)

  # check exclude list
  #

  names = rrd_file.split("\/")
  source = "http://chart.apis.google.com/chart"
  type = "ls"
  colour = "8198A2"
  threshold_colour = "ff0000"
  #data = "1,12,30,40,50,40,30,20,10"
  time = Time.now
  resolution = 10
  start_time = ((time.tv_sec/resolution)*resolution).to_i
  #start_time = time.tv_sec.to_i
  #STDOUT.puts "running rrd command: /usr/bin/rrdtool fetch #{rrd_file} AVERAGE -e start_time -s e-#{interval}m"
  rawdata = `#{CONF['rrdtool_path']}/rrdtool fetch #{rrd_file} AVERAGE -e #{start_time} -r #{resolution} -s e-#{interval}m |#{CONF['awk_path']}/awk '{printf"%s,", $2}'`

  #rawdata = `/usr/bin/rrdtool fetch #{rrd_file} AVERAGE -e (($(date +%s)/900*900)) -s e-#{interval}m |/usr/bin/awk '{printf"%s,", $2}'`
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
  #data.chop!
  #ymin = "0"
  
  
  # 80th percentile stuff, not needed right now

  yshade_colour = "E9F1F4"
  ythresh = "0"
  ymax_shade = "0"
  ymin_shade = "0"
  dimensions = "1000x265"
  
  #uri = "<img src=#{source}?cht=#{type}&chco=#{colour}&chm=r,#{threshold_colour}"
  #uri += ",0,#{ythresh},#{ythresh.to_f+0.00}|r,#{yshade_colour},0,#{ymax_shade}"
  #uri += ",#{ymin_shade}&chds=#{ymin},#{ymax}&chs=#{dimensions}&chd=t:"
  #uri += data
  #uri += ">"
  #puts uri

  #STDOUT.puts mdata
  uri = Gchart.sparkline( :size => '1000x165', 
            :title => "",
            :bg => 'FFCCFF',
            :line_colors => '0077CC',
	    :axis_with_labels => ['x','y','r'],
	    :encoding => 'simple',
	    :data => mdata)

  names = rrd_file.split("\/")
  stat_median = median(mdata)
  is_zero = false
  if (stat_median == 0 and ymin.to_f == 0 && ymax.to_f == 0)
  	is_zero = true
  end
  [uri,names[-1],ymin,ymax,stat_median,is_zero]
 end

#$img_src, $csv_src, $counter, $filter_name, $min, $median, $max, $counter_description
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

# open outputfile

  htmlfile = File.new(CONF['output_path'],"w")
  old = $defout
  $defout = htmlfile
# print header
  puts '<html><head><title>RRD Crunchr v0.1</title><link href="http://numbrcrunchr.com/css/main.css" rel="stylesheet" type="text/css"/><script language="JavaScript" src="http://numbrcrunchr.com/js/datetimepicker.js" type="text/javascript"></script></head><div id="pageHeader"><h1>RRD<font color=#E5702B>Crunchr</font></h1></div>'
# get rrds
  #files = Dir["/opt/collectd/var/lib/collectd/**/*.rrd"]
  files = Dir[CONF['rrd_data_path']]
# print tables
  interval = ARGV[0]
  htmlout = ""
  for file in files
    names = file.split("\/")
    STDOUT.puts "checking #{names[-2]} for exclude"
    if (dir_exclude.include?(names[-2]))
        STDOUT.puts "Skipping #{names[-2]}"
    else
      STDOUT.puts "Processing RRD database: #{file}"
      uri,rrd_name,ymin,ymax,stat_median,is_zero = get_uri(file,interval)
      if (is_zero)
     	htmlout += "#{rrd_name} #{names[-2]}has zero stats"
      else
        htmlout += draw_table(uri,rrd_name,ymin,ymax,stat_median,names[-2]) 
      end
     htmlout += "<br>"
    end
  end
  puts htmlout
end
