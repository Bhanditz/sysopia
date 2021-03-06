module Sysopia
  class ChartTable
    def initialize(stats)
      @comps = Comp.all.order('sensu_name ASC')
      @stats = stats
    end

    def matrics 
      matrics_data = {}
      selected_matrics = ["load_one", "memory_taken", "disk_usage", "io_read", "io_write"]
      #selected_matrics = ["load_one"]
      selected_matrics.each do |matric_name|
        matrics_data[matric_name] = Sysopia::Stat::DATA[matric_name.to_sym].merge({ :name => matric_name, :comps => matric(matric_name) })
      end      
      matrics_data
    end

    def matric(matric_name)    
      comp_data = {}
      @comps.each do |comp|
        comp_data[comp.id] = { :name => comp.sensu_name, :data => [] }
      end  

      #comp_data[@comps[0].id] = { :name => @comps[0].sensu_name, :data => [] }
      #comp_data[@comps[2].id] = { :name => @comps[2].sensu_name, :data => [] }
    
      @stats.each do |stat|       
        #if stat["comp_id"] == @comps[0].id  || stat["comp_id"] == @comps[2].id     
          point = { :x => (stat["timestamp"] + Sysopia.conf.timezone_offset)*1000, :y => stat[matric_name] }         
          comp_data[stat["comp_id"]][:data] << point       
        #end     
      end      
      comp_data.map { |key, value| value }
    end

    private      
  end
end
