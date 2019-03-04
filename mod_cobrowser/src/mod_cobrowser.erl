%%%----------------------------------------------------------------------
%%% File    : mod_cobrowser.erl
%%% Author  : pipo02mix
%%% Purpose : Post availability to API endpoint
%%% Created : 3 April 2017
%%% Id      : $Id: mod_cobrowser.erl 1034 2017-04-01 19:04:17Z pipo02mix $
%%%----------------------------------------------------------------------

-module(mod_cobrowser).

-behaviour(gen_mod).

%% Required by ?DEBUG macros
-include("logger.hrl").
-include("xmpp.hrl").

%% gen_mod API callbacks
-export([start/2, stop/1, on_user_send_packet/1, on_disconnect/3, send_availability/3, getenv/2, depends/2]).

start(Host, _Opts) ->
    ?INFO_MSG("mod_cobrowser starting", []),
    inets:start(),
    ejabberd_hooks:add(user_send_packet, Host, ?MODULE, on_user_send_packet, 50),
    ejabberd_hooks:add(sm_remove_connection_hook, Host, ?MODULE, on_disconnect, 50),
    ?INFO_MSG("mod_cobrowser hooks attached", []),
    ok.

stop(Host) ->
    ?INFO_MSG("mod_cobrowser stopping", []),

    ejabberd_hooks:delete(user_send_packet, Host, ?MODULE, on_user_send_packet, 50),
    ejabberd_hooks:delete(sm_remove_connection_hook, Host, ?MODULE, on_disconnect, 50),
    ok.

-spec on_user_send_packet({stanza(), ejabberd_c2s:state()}) -> {stanza(), ejabberd_c2s:state()}.
on_user_send_packet({#presence{
                        from = #jid{lresource = <<"">>} = From,
                        show = Show,
                        type = unavailable = Type} = Pkt, State} ) ->

      %Jid = binary_to_list(jlib:jid_to_string(From)),
      %BareJid = string:sub_string(Jid,1,string:str(Jid,"/")-1),
      send_availability(From, Type, Show),
    {Pkt, State};
on_user_send_packet({#presence{
                        from = From,
                        show = Show,
                        type = available = Type} = Pkt, State} ) ->

      %Jid = binary_to_list(jlib:jid_to_string(From)),
      %BareJid = string:sub_string(Jid,1,string:str(Jid,"/")-1),
      send_availability(From, Type, Show),
    {Pkt, State};
on_user_send_packet(Acc) ->
    Acc.

on_disconnect(Sid, Jid, Info ) ->
    %StrJid = binary_to_list(jlib:jid_to_string(Jid)),
    %BareJid = string:sub_string(StrJid,1,string:str(StrJid,"/")-1),
    ?INFO_MSG("(mod_cobrowser onDisconnect", []),
    ?DEBUG("(mod_cobrowser)onDisconnect: ~p, ~p, ~p", [ Sid, Jid, Info]),
    send_availability(Jid, unavailable, undefined),

    ok.

send_availability(Jid, Type, Show) ->
      APIEndpoint = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, post_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),

      ShowString = lists:flatten(io_lib:format("~p", [ Show])),
      TypeString = lists:flatten(io_lib:format("~p", [ Type])),

      ?DEBUG("sending packet: ~p type: ~p show: ~p api: ~p", [ Jid, Type, Show, APIEndpoint]),
      URL = "jid=" ++ binary_to_list(Jid#jid.luser) ++ "&type=" ++ TypeString ++ "&show=" ++ ShowString ++ "&host=" ++ binary_to_list(Jid#jid.lserver) ++ "&resource=" ++ binary_to_list(Jid#jid.lresource),
      R = httpc:request(post, {
          binary_to_list(APIEndpoint),
          [],
          "application/x-www-form-urlencoded",
          URL}, [], []),
      {ok, {{"HTTP/1.1", ReturnCode, _}, _, _}} = R,
      ?DEBUG("API request made with result -> ~p ", [ ReturnCode]),
      ReturnCode.

-spec depends(binary(), gen_mod:opts()) -> [{module(), hard | soft}].
depends(_Host, _Opts) ->
  [].

getenv(VarName, DefaultValue) ->
    case os:getenv(VarName) of
        false ->
           DefaultValue;
        Value ->
            Value
    end.
