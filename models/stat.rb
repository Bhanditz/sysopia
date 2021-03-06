class Stat < ActiveRecord::Base
  require 'chronic'
  require 'ruby-units'
  DAY = 86400
  MONTH = 2592000

  class << self

    def degrade_year_old_data
      if Today.new_today?
        timestamp = (Chronic.parse(Sysopia.today) - Unit.new('365d')).to_i
        Stat.where("timestamp < ?", timestamp).destroy_all
      end
    end

    def time_window_and_offset(time_window, offset = nil, stat = nil)
      end_ = Time.now
      end_ = Time.now - Unit.new(offset) if time_window_and_offset
      start = end_ - Unit.new(time_window)
      return last_period(start, end_, stat)
    end

    def start_and_length(start, length, stat = nil)
      start = epoch?(start) ? Time.at(start.to_i) : Chronic.parse(start, :endian_precedence => :little)
      end_ = start + Unit.new(length)
      return last_period(start, end_, stat)
    end

    def start_and_end(start, end_, timestamp = nil, stat = nil)
      start = epoch?(start) ? Time.at(start.to_i) : Chronic.parse(start, :endian_precedence => :little)
      end_ = epoch?(end_) ? Time.at(end_.to_i) : Chronic.parse((end_ || Time.now.to_s), :endian_precedence => :little)
      return last_period(start, end_, stat)
    end

    def ago(ago, stat = nil)
      end_ = Time.now
      start = end_ - Unit.new(ago)
      return last_period(start, end_, stat)
    end

    def last_day(stat = nil)
      end_ = Time.now
      start = end_ - Unit.new("1d")
      last_period(start, end_, stat)
    end

    def last_month(stat = nil)
      end_ = Time.now
      start = end_ - Unit.new("30d")
      last_period(start, end_, stat)
    end

    def last_week(stat = nil)
      end_= Time.now
      start = end_ - Unit.new("7d")
      last_period(start, end_, stat)
    end

    private
    def epoch?(time)
      if time =~ /^[0-9]+$/ && time.length > 7 then true else false end
    end

    def get_granularity(time_range)
      case
      when time_range <= DAY
        "10"
      when time_range <= 2*DAY
        "9"
      when time_range <= 4*DAY
        "8"
      when time_range <= 8*DAY
        "7"
      when time_range <= 16*DAY
        "6"
      when time_range <= 32*DAY
        "5"
      when time_range <= 64*DAY
        "4"
      when time_range <= 128*DAY
        "3"
      when time_range <= 256*DAY
        "2"
      else
        "1"
      end
    end

    def last_period(start, end_, stat = nil)
      start = start.to_i
      end_ = end_.to_i
      time_diff = end_ - start
      granularity_level = get_granularity(time_diff)

      if stat
        return ActiveRecord::Base.connection.select_all("SELECT id, comp_id, timestamp, #{stat} FROM stats WHERE timestamp >= #{start} AND timestamp < #{end_} AND FIND_IN_SET(#{granularity_level}, granularity) > 0"),
          ActiveRecord::Base.connection.select_all("SELECT MAX(timestamp) FROM stats WHERE timestamp >= #{start} AND timestamp < #{end_} AND FIND_IN_SET(#{granularity_level}, granularity) > 0")[0]["MAX(timestamp)"], time_diff
      else
        return ActiveRecord::Base.connection.select_all("SELECT * FROM stats WHERE timestamp >= #{start} AND timestamp < #{end_} AND FIND_IN_SET(#{granularity_level}, granularity) > 0"),
          ActiveRecord::Base.connection.select_all("SELECT MAX(timestamp) FROM stats WHERE timestamp >= #{start} AND timestamp < #{end_} AND FIND_IN_SET(#{granularity_level}, granularity) > 0")[0]["MAX(timestamp)"], time_diff
      end
    end

  end
end
