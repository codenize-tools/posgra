class Posgra::Utils
  module Helper
    def matched?(name, include_r, exclude_r)
      result = true

      if exclude_r
        result &&= name !~ exclude_r
      end

      if include_r
        result &&= name =~ include_r
      end

      result
    end
  end
end
