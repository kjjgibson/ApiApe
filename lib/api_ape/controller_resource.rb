module ApiApe
  class ControllerResource

    require 'api_ape/ape_renderer'

    def self.add_before_filter(controller_class, method, *args)
      options = args.extract_options!
      resource_name = args.first
      filter_method = options.delete(:prepend) ? :prepend_before_filter : :before_filter
      controller_class.send(filter_method, options.slice(:only, :except, :if, :unless)) do |controller|
        ControllerResource.new(controller, resource_name, options.except(:only, :except, :if, :unless)).send(method)
      end
    end

    def self.add_around_filter(controller_class, method, *args)
      options = args.extract_options!
      resource_name = args.first
      filter_method = options.delete(:prepend) ? :prepend_around_filter : :around_filter
      controller_class.send(filter_method, options.slice(:only, :except, :if, :unless)) do |controller, block|
        ControllerResource.new(controller, resource_name, options.except(:only, :except, :if, :unless)).send(method, controller) { block.call }
      end
    end

    def initialize(controller, *args)
      @controller = controller
      @params = controller.params
      @options = args.extract_options!
      @name = args.first
    end

    def load_resource
      unless skip?(:load)
        if load_instance?
          self.resource_instance ||= load_resource_instance
        elsif load_collection?
          self.collection_instance ||= load_collection
        end
      end
    end

    def load_and_render_ape(controller)
      stub_render_method(controller)
      load_resource
      yield
      unstub_render_method(controller)
      ApeRenderer.new(@options[:permitted_fields]).render_ape(@controller, @params, resource_instance || collection_instance)
    end

    def render_ape(controller)
      stub_render_method(controller)
      yield
      unstub_render_method(controller)
      ApeRenderer.new(@options[:permitted_fields]).render_ape(@controller, @params, resource_instance || collection_instance)
    end

    def skip?(behavior)
      options = @controller.class.ape_skipper[behavior][@name]

      if options
        options == {} ||
            options[:except] && !action_exists_in?(options[:except]) ||
            action_exists_in?(options[:only])
      else
        return false
      end
    end

    protected

    def load_resource_instance
      if new_actions.include?(@params[:action].to_sym)
        build_resource
      elsif id_param
        find_resource
      end
    end

    def load_instance?
      member_action?
    end

    def load_collection?
      #TODO: This should probably check something else
      resource_class.respond_to?(:all)
    end

    def load_collection
      #TODO: this should be fleshed out to provide where queries and joins
      resource_class.all
    end

    def build_resource
      resource_class.new(resource_params || {})
    end

    def find_resource
      if @options[:find_by]
        if resource_class.respond_to?("find_by_#{@options[:find_by]}!")
          resource_class.send("find_by_#{@options[:find_by]}!", id_param)
        elsif resource_class.respond_to?("find_by")
          resource_class.send("find_by", { @options[:find_by].to_sym => id_param })
        else
          resource_class.send(@options[:find_by], id_param)
        end
      else
        resource_class.find(id_param)
      end
    end

    def render_action
      @params[:action].to_sym
    end

    def id_param
      @params[id_param_key].to_s if @params[id_param_key]
    end

    def id_param_key
      if @options[:id_param]
        @options[:id_param]
      else
        :id
      end
    end

    def member_action?
      new_actions.include?(@params[:action].to_sym) || ((@params[:id] || @params[@options[:id_param]]) && !collection_actions.include?(@params[:action].to_sym))
    end

    # Returns the class used for this resource. This can be overriden by the :class option.
    # If +false+ is passed in it will use the resource name as a symbol in which case it should
    # only be used for rendering, not loading since there's no class to load through.
    def resource_class
      case @options[:class]
        when false then
          name.to_sym
        when nil then
          namespaced_name.to_s.camelize.constantize
        when String then
          @options[:class].constantize
        else
          @options[:class]
      end
    end

    def resource_instance=(instance)
      @controller.instance_variable_set("@#{instance_name}", instance)
    end

    def resource_instance
      @controller.instance_variable_get("@#{instance_name}") if load_instance?
    end

    def collection_instance=(instance)
      @controller.instance_variable_set("@#{instance_name.to_s.pluralize}", instance)
    end

    def collection_instance
      @controller.instance_variable_get("@#{instance_name.to_s.pluralize}")
    end

    def name
      @name || name_from_controller
    end

    def resource_params
      if parameters_require_sanitizing? && params_method.present?
        return case params_method
                 when Symbol then
                   @controller.send(params_method)
                 when String then
                   @controller.instance_eval(params_method)
                 when Proc then
                   params_method.call(@controller)
               end
      else
        resource_params_by_namespaced_name
      end
    end

    def parameters_require_sanitizing?
      save_actions.include?(@params[:action].to_sym) || resource_params_by_namespaced_name.present?
    end

    def resource_params_by_namespaced_name
      if @options[:instance_name] && @params.has_key?(extract_key(@options[:instance_name]))
        @params[extract_key(@options[:instance_name])]
      elsif @options[:class] && @params.has_key?(extract_key(@options[:class]))
        @params[extract_key(@options[:class])]
      else
        @params[extract_key(namespaced_name)]
      end
    end

    def params_method
      params_methods.each do |method|
        return method if (method.is_a?(Symbol) && @controller.respond_to?(method, true)) || method.is_a?(String) || method.is_a?(Proc)
      end
      nil
    end

    def params_methods
      methods = ["#{@params[:action]}_params".to_sym, "#{name}_params".to_sym, :resource_params]
      methods.unshift(@options[:param_method]) if @options[:param_method].present?
      methods
    end

    def namespace
      @params[:controller].split('/')[0..-2]
    end

    def namespaced_name
      [namespace, name.camelize].flatten.map(&:camelize).join('::').singularize.constantize
    rescue NameError
      name
    end

    def name_from_controller
      @params[:controller].split('/').last.singularize
    end

    def instance_name
      @options[:instance_name] || name
    end

    def collection_actions
      [:index] + Array(@options[:collection])
    end

    def new_actions
      [:new, :create] + Array(@options[:new])
    end

    def save_actions
      [:create, :update]
    end

    private

    def action_exists_in?(options)
      Array(options).include?(@params[:action].to_sym)
    end

    def extract_key(value)
      value.to_s.underscore.gsub('/', '_')
    end

    def stub_render_method(controller)
      controller.class.send(:alias_method, :render_old, :render)
      controller.class.send(:define_method, :render) {}
    end

    def unstub_render_method(controller)
      controller.class.send(:alias_method, :render, :render_old)
      controller.class.send(:remove_method, :render_old)
    end
  end
end