defmodule ProxyIps.Sources do
  @moduledoc """
  Defines proxy sources for different protocols
  """

  @spec socks5_sources() :: [String.t()]
  def socks5_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/socks5.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks5.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/socks5/data.txt",
      "https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/socks5.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/socks5.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/main/SOCKS5.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/main/SOCKS5.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/main/socks5.txt",
      "https://raw.githubusercontent.com/zloi-user/hideip.me/master/socks5.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/refs/heads/main/socks5/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/socks5.txt"
    ]
  end

  @spec socks4_sources() :: [String.t()]
  def socks4_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/socks4.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/socks4.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/socks4/data.txt",
      "https://raw.githubusercontent.com/hookzof/socks5_list/master/socks4.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/socks4.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/socks4.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/main/SOCKS4.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/main/SOCKS4.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/main/proxies/socks4.txt",
      "https://raw.githubusercontent.com/zloi-user/hideip.me/master/socks4.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/refs/heads/main/socks4/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/socks4.txt"
    ]
  end

  @spec http_sources() :: [String.t()]
  def http_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/http.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/http/data.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/http.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/http.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/main/HTTP.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/main/HTTP.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/main/proxies/http.txt",
      "https://raw.githubusercontent.com/zloi-user/hideip.me/master/http.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/refs/heads/main/http/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/http.txt",
      "https://raw.githubusercontent.com/mthcht/awesome-lists/main/Lists/Threat/proxy_list_ip.txt",
      "https://raw.githubusercontent.com/mmpx12/proxy-list/master/http.txt",
      "https://raw.githubusercontent.com/hookzof/socks5_list/master/http.txt",
      "https://api.proxyscrape.com/v2/?request=get&protocol=http"
    ]
  end

  @spec https_sources() :: [String.t()]
  def https_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/https.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/https.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/https/data.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/main/https.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/https.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/https.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/main/proxies/https.txt",
    ]
  end

  @spec all_sources() :: %{atom() => [String.t()]}
  def all_sources do
    %{
      socks5: socks5_sources(),
      socks4: socks4_sources(),
      http: http_sources(),
      https: https_sources()
    }
  end
end
