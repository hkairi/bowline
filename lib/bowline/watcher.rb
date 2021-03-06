module Bowline
  class Watcher
    # Callbacks on steroids.
    # Add callbacks as class methods, or instance ones.
    # 
    # class MyClass
    #   extend Bowline::Watcher::Base
    #   watch :update, :create
    # 
    #   def self.update
    #     watcher.call(:update)
    #   end
    # 
    #   def create
    #     watcher.call(:create)
    #   end
    # end
    # 
    # MyClass.on_update { puts 'update' }
    # MyClass.new.on_create { puts 'create' }
    module Base
      # Create a helper method to easily add new callbacks.
      # Example:
      #   watch :on_load
      #   on_load { puts "Loaded!" }
      def watch(*names)
      	names.each do |name|
          # Because define_method only takes a block,
          # which doesn't accept multiple arguments
          script = <<-RUBY
            def #{name}(*args, &block)
              watcher.append(:#{name}, *args, &block)
            end
          RUBY
          instance_eval script
          class_eval    script
  			end
      end
      
      def watcher
        @watcher ||= Watcher.new
      end
    end
  
    class Callback
      attr_reader :event, :prok
    
      def initialize(watcher, event, prok)
      	@watcher, @event, @prok = watcher, event, prok
      end
      
      # Execute callback
      def call(*args)
      	@prok.call(*args)
      end
      
      # Remove callback from watcher
      def remove
      	@watcher.remove(@event, @prok)
      end
    end
  
    def initialize
      @listeners = {}
    end
    
    # Add new method/proc to a specific event.
    def append(event, method = nil, &block)
      callback = Callback.new(self, event, method||block)
      (@listeners[event] ||= []) << callback
      callback
    end
    
    # Call an event's callbacks with provided arguments.
    def call(event, *args)
      return unless @listeners[event]
      @listeners[event].each do |callback|
        callback.call(*args)
      end
    end
    
    # Remove an specific callback on an event,
    # or all an event's callbacks.
    def remove(event, value=nil)
      return unless @listeners[event]
      if value
        @listeners[event].delete(value)
        if @listeners[event].empty?
          @listeners.delete(event)
        end
      else
        @listeners.delete(event)
      end
    end
    
    # Clear all events and callbacks.
    def clear
      @listeners = {}
    end
  end
end