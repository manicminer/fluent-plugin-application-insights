require 'fluent/plugin/filter'

module Fluent::Plugin
  class PassThruFilter < Filter
    Fluent::Plugin.register_filter('application_insights', self)

    desc "Base instance type for AppInsights"
    config_param :base_type, :string

    desc "Role tag value"
    config_param :role, :string

    desc "Seconds field to convert to standard duration"
    config_param :seconds_field, :string

    def configure(conf)
      super
    end

    def filter(tag, time, record)
      if @seconds_field
        t = Rational(record[@seconds_field])
        record['duration'] = Time.at(t).utc.strftime('%H:%M:%S.%6N')
      end
      status = Integer(record['responseCode'])
      data = {}
      fields = ['id', 'duration', 'responseCode', 'source', 'name', 'url']
      fields.each do |f|
        if record.key?(f)
          data[f] = record[f]
          record.delete(f)
        end
      end
      out = {
        "data" => {
          "baseType" => @base_type,
          "baseData" => {
            "ver" => 2,
            "success" => status.between?(200,399),
            "properties" => record,
          }.merge(data),
        },
      }
      if @tags
        out['tags'] = {
          "ai.cloud.role" => @role
        }
      end
      out
    end
  end
end
