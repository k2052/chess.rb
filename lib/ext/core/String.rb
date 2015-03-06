class String
  def is_numeric?
    match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end

  def mask
    gsub(/\\/, '\\')
  end
end
