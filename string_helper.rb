def titleize(str)
  str.split(/[^a-zA-Z0-9]+/).map(&:capitalize).join
end
