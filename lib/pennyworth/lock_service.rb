# Copyright (c) 2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

module Pennyworth
  class LockService
    attr_reader :lock_server_host
    attr_reader :lock_server_port

    def initialize(lock_server_address)
      fields = lock_server_address.split(":")
      @lock_server_host = fields[0]
      @lock_server_port = fields[1]
      @sockets = {}
    end

    def socket(lock_name)
      if !@sockets.has_key?(lock_name)
        @sockets[lock_name] = TCPSocket.new(@lock_server_host, @lock_server_port)
      end
      @sockets[lock_name]
    end

    def request_lock(lock_name)
      socket(lock_name).puts("g #{lock_name}")
      response = socket(lock_name).gets
      if response =~ /^1/
        return true
      elsif response =~ /^0/
        return false
      else
        raise LockError.new("Error, received: #{response}")
      end
    end

    def keep_lock
      # Sleep forever to keep process running to keep TCP connection to lock
      # server open. When the process is ended the connection is closed and the
      # lock is released. Users can end the process and release the lock with
      # Ctrl-C.
      sleep
    end

    def release_lock(lock_name)
      if !@sockets[lock_name]
        raise LockError.new("Lock '#{lock_name}' doesn't exist")
      end
      @sockets[lock_name].close
      @sockets.delete(lock_name)
    end

    def locked?(lock_name)
      socket(lock_name).puts("i #{lock_name}")
      response = socket(lock_name).gets
      if response =~ /^1/
        return true
      else
        return false
      end
    end

    def info(lock_name)
      if locked?(lock_name)
        socket(lock_name).puts("d #{lock_name}")
        response = socket(lock_name).gets
        response =~ /^#{lock_name}: (.*):/
        client = $1
        return "'#{lock_name}' is locked by #{client}"
      else
        return "'#{lock_name}' is not locked"
      end
    end
  end
end
