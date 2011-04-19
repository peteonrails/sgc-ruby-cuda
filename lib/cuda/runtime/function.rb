#
# Copyright (c) 2010-2011 Chung Shin Yee
#
#       shinyee@speedgocomputing.com
#       http://www.speedgocomputing.com
#       http://github.com/xman/sgc-ruby-cuda
#       http://rubyforge.org/projects/rubycuda
#
# This file is part of SGC-Ruby-CUDA.
#
# SGC-Ruby-CUDA is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SGC-Ruby-CUDA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SGC-Ruby-CUDA.  If not, see <http://www.gnu.org/licenses/>.
#

require 'cuda/runtime/ffi-cuda'
require 'cuda/runtime/cuda'
require 'cuda/runtime/error'
require 'cuda/runtime/stream'
require 'memory/pointer'
require 'dl'


module SGC
module Cuda

class CudaFunction

    attr_reader :name


    def initialize(name)
        @name = name
    end


    def attributes
        a = CudaFunctionAttributes.new
        status = API::cudaFuncGetAttributes(a.to_ptr, @name)
        Pvt::handle_error(status)
        a
    end


    def cache_config=(config)
        status = API::cudaFuncSetCacheConfig(@name, config)
        Pvt::handle_error(status)
        config
    end


    def launch
        status = API::cudaLaunch(@name)
        Pvt::handle_error(status)
        self
    end


    # Configure the settings for the next kernel launch.
    # @param [Dim3] grid_dim The 3D grid dimensions x, y, z to launch.
    # @param [Dim3] block_dim The 3D block dimensions x, y, z to launch.
    # @param [Integer] shared_mem_size Number of bytes of dynamic shared memory for each thread block.
    # @param [Integer, CudaStream] stream The stream to launch this kernel function on.
    #     Setting _stream_ to anything other than an instance of CudaStream will execute on the default stream 0.
    # @return [Class] This class.
    def self.configure(grid_dim, block_dim, shared_mem_size = 0, stream = 0)
        s = Pvt::parse_stream(stream)
        status = API::cudaConfigureCall(grid_dim, block_dim, shared_mem_size, s)
        Pvt::handle_error(status)
        self
    end


    def self.setup(*args)
        offset = 0
        args.each do |x|
            case x
                when Fixnum
                    p = FFI::MemoryPointer.new(:int)
                    p.write_int(x)
                    size = 4
                when Float
                    p = FFI::MemoryPointer.new(:float)
                    p.write_float(x)
                    size = 4
                when SGC::Memory::MemoryPointer
                    p = x.ref
                    size = FFI::MemoryPointer.size
                else
                    raise TypeError, "Invalid type of argument #{x.to_s}."
            end
            offset = align_up(offset, size)
            status = API::cudaSetupArgument(p, size, offset)
            Pvt::handle_error(status)
            offset += size
        end
    end


    def self.load_lib(name)
        raise NotImplementedError
    end


    def self.load_lib_file(name)
        @@libs << DL::dlopen(name)
        # API::ffi_lib(name)
        self
    end


    def self.unload_all_libs
        @@libs.each do |h|
            h.close
        end
        @@libs = []
        self
    end


    @@libs = [] # @private

private

    def self.align_up(offset, alignment)
        (offset + alignment - 1) & ~(alignment - 1)
    end

end

end # module
end # module
