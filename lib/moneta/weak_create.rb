module Moneta

  # Adds non-atomic create support to the underlying store.
  #
  # This proxy should appear before Expires in the stack if both are 
  # used.
  class Create < Proxy

    include CreateSupport

  end

end
