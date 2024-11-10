require "http/server"

# TODO: Write documentation for `Ip`
module Ip
  VERSION = "0.1.0"

  def self.hostname_from_PITR(ip : String) : String
    hostname = IO::Memory.new
    shell = Process.new("/bin/sh", input: :pipe, output: hostname)
    shell.input << "dig -x #{ip} | grep PTR | grep -v ';' | awk '{print $5}'\n"
    shell.wait
    "#{hostname}"
  end

  def self.hostname_from_SOA(ip : String) : String
    hostname = IO::Memory.new
    shell = Process.new("/bin/sh", input: :pipe, output: hostname)
    shell.input << "dig -x #{ip} | grep SOA | grep -v ';' | awk '{print $6}'\n"
    shell.wait
    "#{hostname}"
  end

  server = HTTP::Server.new do |context|
    p! context.request
    headers = context.request.headers
    rem = context.request.remote_address
    ip = headers.fetch("X-Forwarded-For", "#{rem}".split(":")[0]).split(",")[0]
    host_pitr = self.hostname_from_PITR(ip)
    host_soa = self.hostname_from_SOA(ip)
    context.response.content_type = "text/plain"
    context.response.print "#{ip}\n"
    if !host_pitr.empty? && !host_pitr.includes?("NXDOMAIN")
      context.response.print "#{host_pitr}\n"
    end
    if !host_soa.empty? && !host_soa.includes?("NXDOMAIN")
      context.response.print "#{host_soa}\n"
    end
  end

  address = server.bind_tcp "0.0.0.0", 8080
  puts "Listening on http://#{address}"
  server.listen
end
