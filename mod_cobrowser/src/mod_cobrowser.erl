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
-export([start/2, stop/1, send_stoping_event/1, on_user_send_packet/1, on_disconnect/3, send_availability/3, getenv/2, depends/2]).

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
    ?INFO_MSG("mod_cobrowser hooks deattached ~p", [Host]),
    send_stoping_event(Host),
    ok.

-spec on_user_send_packet({stanza(), ejabberd_c2s:state()}) -> {stanza(), ejabberd_c2s:state()}.
on_user_send_packet({#presence{
                        from = #jid{lresource = <<"">>} = From,
                        show = Show,
                        type = unavailable = Type} = Pkt, State} ) ->
      
      ?INFO_MSG("mod_cobrowser on_user_send_packet1", []),
      send_availability(From, Type, Show),
    {Pkt, State};
on_user_send_packet({#presence{
                        from = From,
                        show = Show,
                        type = available = Type} = Pkt, State} ) ->
      ?INFO_MSG("mod_cobrowser on_user_send_packet2", []),
      send_availability(From, Type, Show),
    {Pkt, State};
on_user_send_packet(Acc) ->
    Acc.

on_disconnect(Sid, Jid, Info ) ->
    ?INFO_MSG("mod_cobrowser on_disconnect: Sid: ~p Info: ~p", [Sid, Info]),
    send_availability(Jid, unavailable, undefined),

    ok.

send_stoping_event(Host) -> 
    Token = gen_mod:get_module_opt(Host, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
    APIEndpoint = gen_mod:get_module_opt(Host, ?MODULE, post_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
    if
      APIEndpoint ->
        ?INFO_MSG("Posting send_stoping_event To ~p Token ~p",[APIEndpoint, Token]),
        Data = string:join(["stopping=", binary_to_list(Host)], ""),
        Request = {binary_to_list(APIEndpoint), [{"Authorization", binary_to_list(Token)}], "application/x-www-form-urlencoded", Data},
        httpc:request(post, Request,[],[]),
        ?INFO_MSG("post request sent", []);
      true -> []
    end.

send_availability(Jid, Type, Show) ->
    Token = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
    APIEndpoint = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, post_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),

    ShowString = lists:flatten(io_lib:format("~p", [ Show])),
    TypeString = lists:flatten(io_lib:format("~p", [ Type])),

    ?INFO_MSG("mod_cobrowser send availability Packet: ~p Type: ~p Show: ~p",[Jid, Type, Show]),

    Data = string:join(["jid=", binary_to_list(Jid#jid.luser), "&type=", TypeString, "&show=", ShowString, "&host=", binary_to_list(Jid#jid.lserver), "&resource=", binary_to_list(Jid#jid.lresource)], ""),
    R = httpc:request(post, {
        binary_to_list(APIEndpoint),
        [{"Authorization", binary_to_list(Token)}],
        "application/x-www-form-urlencoded",
        Data}, [], []),
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
