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

require "spec_helper"

describe Pennyworth::LockService do
  let(:lock_service) { Pennyworth::LockService.new("lock.example.com:9999") }

  it "creates lock object" do
    expect(lock_service.lock_server_host).to eq("lock.example.com")
    expect(lock_service.lock_server_port).to eq("9999")
  end

  it "acquires lock" do
    socket = double
    expect(TCPSocket).to receive(:new).and_return(socket)
    expect(socket).to receive(:puts).with("g my_test")
    expect(socket).to receive(:gets).
      and_return("1 Lock Get Success: my_test")

    expect(lock_service.request_lock("my_test")).to be(true)
  end

  it "fails to acquire lock" do
    socket = double
    expect(TCPSocket).to receive(:new).and_return(socket)
    expect(socket).to receive(:puts).with("g my_test")
    expect(socket).to receive(:gets).
      and_return("0 Lock Get Failure: my_test")

    expect(lock_service.request_lock("my_test")).to be(false)
  end

  it "fails to release non-existing lock" do
    expect {
      lock_service.release_lock("inexisting lock")
    }.to raise_error(Pennyworth::LockError)
  end

  it "releases lock" do
    socket = double
    expect(TCPSocket).to receive(:new).and_return(socket)
    expect(socket).to receive(:puts).with("g my_test")
    expect(socket).to receive(:gets).
      and_return("1 Lock Get Success: my_test")

    expect(lock_service.request_lock("my_test")).to be(true)

    expect(socket).to receive(:close)

    lock_service.release_lock("my_test")
  end

  it "returns locked status" do
    socket = double
    expect(TCPSocket).to receive(:new).and_return(socket)

    expect(socket).to receive(:puts).with("i my_test")
    expect(socket).to receive(:gets).
      and_return("1 Lock Is Locked: my_test")

    expect(socket).to receive(:puts).with("d my_test")
    expect(socket).to receive(:gets).
      and_return("my_test: 172.16.254.1:49716")

    expect(lock_service.info("my_test")).
      to eq "'my_test' is locked by 172.16.254.1"
  end

  it "returns unlocked status" do
    socket = double
    expect(TCPSocket).to receive(:new).and_return(socket)

    expect(socket).to receive(:puts).with("i my_test")
    expect(socket).to receive(:gets).
      and_return("0 Lock Not Locked: my_test")

    expect(lock_service.info("my_test")).
      to eq "'my_test' is not locked"
  end
end
