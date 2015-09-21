##
# reversal.rb: decompiling YARV instruction sequences
#
# Copyright 2010 Michael J. Edgar, michael.j.edgar@dartmouth.edu
#
# MIT License, see LICENSE file in gem package

$:.unshift(File.dirname(__FILE__))

module Reversal
  autoload :Instructions, "reversal/instructions"
end

require 'reversal/ir'
require 'reversal/iseq'
require 'reversal/reverser'
require 'reversal/bugreport'


module Reversal
  VERSION = "0.9.0"

  class InternalDecompilerError < StandardError
  end

  @@klassmap = Hash.new do |h, k|
    h[k] = {
      :methods => [],
      :includes => [],
      :extends => [],
      :super => nil,
    }
  end

  def decompile(iseq)
    Reverser.new(iseq).to_ir.to_s
  end
  module_function :decompile

  def decompile_into(iseq, klass)
    begin
      decompiled = self.decompile(iseq)
    rescue InternalDecompilerError
      if ENV['UNRUBBY_REPORT_BUG']
        BugReport.new(iseq).dump
        exit!(1)
      end
    end
    @@klassmap[klass][:methods] << decompiled
  end
  module_function :decompile_into

  def dump_klassmap
    @@klassmap.each do |klass, attrs|
      if klass.is_a? Class
        sooper = attrs[:super]
        puts "class #{klass.inspect}#{" < #{sooper}" if sooper}\n"
      elsif klass.is_a? Module
        puts "module #{klass.inspect}\n"
      else
        raise "No idea how to repr #{klass.inspect}"
      end

      attrs[:includes].each do |i|
        puts "  include " + i.inspect
      end

      attrs[:extends].each do |i|
        puts "  extend " + i.inspect
      end

      attrs[:methods].each do |m|
        m.lines.each do |line|
          puts "  " + line
        end
      end
      puts "end"
    end
  end

  module_function :dump_klassmap
  def mark_included(obj, mod)
    @@klassmap[mod][:includes] << obj
  end
  module_function :mark_included

  def mark_extended(obj, mod)
    @@klassmap[mod][:extends] << obj
  end
  module_function :mark_extended

  def register_class(klass, sooper)
    @@klassmap[klass][:super] = sooper
  end
  module_function :register_class
end

at_exit {
  Reversal.dump_klassmap
}

module Reversal
  LOADED = true
end
