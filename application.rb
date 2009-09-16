class Rrdcrunchr < Merb::Controller
	#test
  def _template_location(action, type = nil, controller = controller_name)
    controller == "layout" ? "layout.#{action}.#{type}" : "#{action}.#{type}"
  end

  def index
    @hosts = get_hosts.sort
    @rrdtypes = get_rrdtypes.sort
    #@hosts = get_hosts
    #@rrdtypes = get_rrdtypes
    @hosts.inspect
    @rrdtypes.inspect
    @rrdgroups = ["All"]
    @rrdp = get_rrd_path
    
    render
    
  end

  def foo
    render
  end
  
end
