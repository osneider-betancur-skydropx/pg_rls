# frozen_string_literal: true

module PgRls
  # Current Tenant State
  class Current < ::ActiveSupport::CurrentAttributes
    attribute(*PgRls.current_attributes.dup.push(:tenant))

    PgRls.current_attributes.each do |attribute|
      define_method(attribute) do
        @attributes[attribute] ||= fetch_attribute(attribute)
      end
    end

    def fetch_attribute(attribute)
      klass_name = attribute.to_s.gsub("__", "/").classify

      send(:"#{attribute}=", klass_name.constantize.first)
    end

    def tenant=(tenant)
      @attributes[:tenant_history] ||= []
      @attributes[:tenant_history] << @attributes[:tenant] if @attributes[:tenant].present?
      @attributes[:tenant] = tenant
      tenant&.set_rls if Rails.env.test?
      tenant
    end

    def reset
      history = @attributes[:tenant_history] || []

      super

      @attributes[:tenant_history] = history

      if history.any?
        @attributes[:tenant] = history.last
        @attributes[:tenant]&.set_rls if Rails.env.test?
      else
        @attributes[:tenant]&.reset_rls if Rails.env.test?
      end

      @attributes[:tenant]
    end
  end
end
