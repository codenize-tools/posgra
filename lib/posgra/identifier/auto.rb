class Posgra::Identifier::Auto
  def initialize(output, options = {})
    @output = output
    @options = options
  end

  def identify(user)
    password = mkpasswd
    puts_password(user, password)
    password
  end

  private

  def mkpasswd(len = 8)
    [*1..9, *'A'..'Z', *'a'..'z'].shuffle.slice(0, len).join
  end

  def puts_password(user, password)
    open_output do |f|
      f.puts("#{user},#{password}")
    end
  end

  def open_output
    return if @options[:dry_run]

    if @output == '-'
      yield($stdout)
      $stdout.flush
    else
      open(@output, 'a') do |f|
        yield(f)
        f.flush
      end
    end
  end
end
