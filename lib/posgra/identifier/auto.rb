class Posgra::Identifier::Auto
  def initialize(output, options = {})
    @output = output
    @options = options
  end

  def identify(user)
    password = mkpasswd([@options[:password_length].to_i, 8].max)
    puts_password(user, password)
    password
  end

  private

  def mkpasswd(len)
    sources = [
      (1..9).to_a,
      ('A'..'Z').to_a,
      ('a'..'z').to_a,
    ].shuffle

    passwd = []

    len.times do |i|
      src = sources[i % sources.length]
      passwd << src.shuffle.shift
    end

    passwd.join
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
