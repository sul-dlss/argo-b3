# frozen_string_literal: true

# Methods for working with cocina object locks
class LockSupport
  # find returns the lock as an ETag (possibly with a -gzip suffix), while find_all returns it bare.
  # @return [String, nil] the lock without the ETag wrapping, as DSA reads it
  def self.bare_lock_from(lock)
    return lock unless lock&.start_with?('W/')

    lock[3..-2].delete_suffix('-gzip')
  end

  # @return [Boolean] whether the locks identify the same state of the object
  def self.same?(lock, other_lock)
    return false if lock.nil? || other_lock.nil?

    bare_lock_from(lock) == bare_lock_from(other_lock)
  end
end
