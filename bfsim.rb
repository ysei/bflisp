#!/usr/bin/env ruby

require './common'

class BFSim
  def initialize
    @a = 0
    @b = 0
    @c = 0
    @d = 0
    @pc = 0
    @bp = 0
    @sp = 0
    @cond = false
    @mem = [0] * 65536
  end

  def set(r, v)
    case r
    when :a
      @a = v
    when :b
      @b = v
    when :c
      @c = v
    when :d
      @d = v
    when :bp
      @bp = v
    when :sp
      @sp = v
    when :pc
      @pc = v
    else
      raise "invalid dest reg #{r}"
    end
  end

  def src(o)
    case o
    when :a
      @a
    when :b
      @b
    when :c
      @c
    when :d
      @d
    when :bp
      @bp
    when :sp
      @sp
    when :pc
      @pc
    else
      o
    end
  end

  def run(code, data)
    data.each do |d, i|
      @mem[i] = d
    end

    running = true
    while running
      op, *args, lineno = *code[@pc]

      hp = @mem[256]
      if @sp != 0 && @sp <= hp
        STDERR.puts "stack overflow!!! #{@sp} vs #{hp}"
      end

      if $verbose
        STDERR.puts "PC=#@pc A=#@a B=#@b C=#@c D=#@d SP=#@sp BP=#@bp"
        STDERR.print "STK:"
        32.times{|i|
          STDERR.print " #{@mem[-32+i]}"
        }
        STDERR.puts
        STDERR.puts "#{op} #{args} at #{lineno}"
      end

      if !op
        raise "out of bound pc=#{@pc}"
      end
      @pc += 1

      case op
      when :mov
        set(args[0], src(args[1]))

      when :add
        set(args[0], (src(args[0]) + src(args[1])) & 65535)

      when :sub
        set(args[0], (src(args[0]) - src(args[1])) & 65535)

      when :load
        v = @mem[src(args[1])]
        #STDERR.puts "load addr=#{src(args[1])} (#{v}) @#{lineno}"
        set(args[0], @mem[src(args[1])])

      when :store
        v = src(args[0])
        #STDERR.puts "store addr=#{src(args[1])} (#{v}) @#{lineno}"
        @mem[src(args[1])] = src(args[0])

      when :jmp, :jeq, :jne, :jlt, :jgt, :jle, :jge
        ok = true
        case op
        when :jeq
          ok = src(args[1]) == src(args[2])
        when :jne
          ok = src(args[1]) != src(args[2])
        when :jlt
          ok = src(args[1]) < src(args[2])
        when :jgt
          ok = src(args[1]) > src(args[2])
        when :jle
          ok = src(args[1]) <= src(args[2])
        when :jge
          ok = src(args[1]) >= src(args[2])
        end
        if ok
          @pc = src(args[0])
        end

      when :eq
        set(args[0], src(args[0]) == src(args[1]) ? 1 : 0)
      when :ne
        set(args[0], src(args[0]) != src(args[1]) ? 1 : 0)
      when :lt
        set(args[0], src(args[0]) < src(args[1]) ? 1 : 0)
      when :gt
        set(args[0], src(args[0]) > src(args[1]) ? 1 : 0)
      when :le
        set(args[0], src(args[0]) <= src(args[1]) ? 1 : 0)
      when :ge
        set(args[0], src(args[0]) >= src(args[1]) ? 1 : 0)

      when :putc
        putc src(args[0])

      when :getc
        c = STDIN.read(1)
        set(args[0], c ? c.ord : 0)

      when :exit
        running = false
        break
      end
    end

  end
end

if $0 == __FILE__
  require './bfasm'

  asm = BFAsm.new
  code, data = asm.parse(File.read(ARGV[0]))

  sim = BFSim.new
  sim.run(code, data)
end