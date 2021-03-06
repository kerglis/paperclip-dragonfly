module PaperclipDragonfly
  module Dragonfly
    module ActiveModelExtensions
      module ClassMethods
        mattr_accessor :replacement_regex

        def custom_path_style
          @custom_path_style or ::Rails.configuration.paperclip_dragonfly.custom_path_style
        end

        def dragonfly_for(*options)
          accessor = options.first
          if options.size == 2
            options = options.last
            set_df_scope(options[:scope]) if options[:scope]
            @custom_path_style = options[:custom_path_style]
          end
          send :include, ::PaperclipDragonfly::CustomPathExtension
          df_rails_image_accessor accessor
          image_accessor accessor
        end

        def df_scope
          @scope ||= self.table_name
        end

        # Dragonfly scope setter
        def set_df_scope(scope)
          @scope = scope
        end
      end
    end
  end
end

module Dragonfly
  module ActiveModelExtensions
    module InstanceMethods
      private
      alias_method :original_save_dragonfly_attachments, :save_dragonfly_attachments
      def save_dragonfly_attachments
        original_save_dragonfly_attachments if (path_style == :time_partition && new_record?) || ([:custom, :id_partition].include?(path_style) && !new_record?)
      end
    end
    module ClassMethods
      alias_method :original_register_dragonfly_app, :register_dragonfly_app
      def register_dragonfly_app(macro_name, app)
        original_register_dragonfly_app(macro_name, app)
        (class << self; self; end).class_eval do
          # Registers the after_save callback
          define_method "df_rails_#{macro_name}" do |attribute, &config_block|
            # Add callbacks
            after_save :save_dragonfly_attachments
          end
        end
      end
    end
    class Attachment
      alias_method :original_initialize, :initialize
      def initialize(model)
        original_initialize(model)
        app.datastore.scope_for = @model
      end
    end
  end
end