class Rrdcrunchr < Merb::Controller

  def _template_location(action, type = nil, controller = controller_name)
    controller == "layout" ? "layout.#{action}.#{type}" : "#{action}.#{type}"
  end

  def index
    @all_hosts = get_hosts.sort
    if (params['host'] != 'All')
	@hosts = [params['host']]	
    else
    	@hosts = get_hosts.sort
    end
    @rrdtypes = get_rrdtypes.sort
    @hosts.inspect
    @rrdtypes.inspect
    @rrdgroups = ["All"]
    @rrdp = get_rrd_path
    @types = ['load/load.rrd']
    if (params['type'])
    	#@types = params['type'].split('/')
	@types = params['type']
    end
    
    render
    
  end

  def foo
    render
  end
  
end
