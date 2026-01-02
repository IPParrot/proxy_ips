defmodule ProxyIps.Sources do
  @moduledoc """
  Defines proxy sources for different protocols
  """

  @spec socks5_sources() :: [String.t()]
  def socks5_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/refs/heads/master/socks5.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/refs/heads/master/socks5.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/refs/heads/main/proxies/protocols/socks5/data.txt",
      "https://raw.githubusercontent.com/hookzof/socks5_list/refs/heads/master/proxy.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/socks5.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/refs/heads/main/socks5_checked.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/refs/heads/main/socks5_proxies.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/refs/heads/main/SOCKS5.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/refs/heads/main/proxies/socks5.txt",
      "https://github.com/zloi-user/hideip.me/raw/refs/heads/master/socks5.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/main/socks5/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/refs/heads/main/proxies/socks5.txt"
    ]
  end

  @spec socks4_sources() :: [String.t()]
  def socks4_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/refs/heads/master/socks4.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/refs/heads/master/socks4.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/refs/heads/main/proxies/protocols/socks4/data.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/socks4.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/refs/heads/main/socks4_checked.txt",
      "https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/refs/heads/master/socks4.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/refs/heads/main/socks4_proxies.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/refs/heads/main/SOCKS4.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/refs/heads/main/proxies/socks4.txt",
      "https://github.com/zloi-user/hideip.me/raw/refs/heads/master/socks4.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/main/socks4/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/refs/heads/main/proxies/socks4.txt"
    ]
  end

  @spec http_sources() :: [String.t()]
  def http_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/refs/heads/master/http.txt",
      "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/refs/heads/master/http.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/refs/heads/main/proxies/protocols/http/data.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/http.txt",
      "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/refs/heads/main/http_checked.txt",
      "https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/refs/heads/master/http.txt",
      "https://raw.githubusercontent.com/dpangestuw/Free-Proxy/refs/heads/main/http_proxies.txt",
      "https://raw.githubusercontent.com/Argh94/Proxy-List/refs/heads/main/HTTP.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/refs/heads/main/proxies/http.txt",
      "https://raw.githubusercontent.com/mthcht/awesome-lists/refs/heads/main/Lists/PROXY/ALL_PROXY_Lists.csv",
      "https://raw.githubusercontent.com/mmpx12/proxy-list/refs/heads/master/proxies.txt",
      "https://raw.githubusercontent.com/mmpx12/proxy-list/refs/heads/master/http.txt",
      "https://github.com/zloi-user/hideip.me/raw/refs/heads/master/http.txt",
      "https://raw.githubusercontent.com/ClearProxy/checked-proxy-list/main/http/raw/all.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/refs/heads/main/proxies/http.txt"
    ]
  end

  @spec https_sources() :: [String.t()]
  def https_sources do
    [
      "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/refs/heads/master/https.txt",
      "https://raw.githubusercontent.com/proxifly/free-proxy-list/refs/heads/main/proxies/protocols/https/data.txt",
      "https://raw.githubusercontent.com/zebbern/Proxy-Scraper/refs/heads/main/https.txt",
      "https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/refs/heads/master/https.txt",
      "https://raw.githubusercontent.com/Firmfox/Proxify/refs/heads/main/proxies/https.txt",
      "https://github.com/zloi-user/hideip.me/raw/refs/heads/master/https.txt",
      "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/refs/heads/main/proxies/https.txt"
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
