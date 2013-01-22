def hostname
  @hostname ||= `hostname`.chomp
end