# encoding: utf-8
require 'test_helper'

class ChatTest < ActiveSupport::TestCase
  agent1 = nil
  agent2 = nil
  test 'aaa - setup' do

    # create base
    groups = Group.all
    roles  = Role.where( name: %w(Agent) )
    agent1 = User.create_or_update(
      login: 'ticket-chat-agent1@example.com',
      firstname: 'Notification',
      lastname: 'Agent1',
      email: 'ticket-chat-agent1@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:37:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
    agent2 = User.create_or_update(
      login: 'ticket-chat-agent2@example.com',
      firstname: 'Notification',
      lastname: 'Agent2',
      email: 'ticket-chat-agent2@example.com',
      password: 'agentpw',
      active: true,
      roles: roles,
      groups: groups,
      updated_at: '2015-02-05 16:38:00',
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  test 'default test' do

    Chat.delete_all
    Chat::Session.delete_all
    Chat::Message.delete_all
    Chat::Agent.delete_all
    Setting.set('chat', false)
    chat = Chat.create_or_update(
      name: 'default',
      max_queue: 5,
      note: '',
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )

    # check if feature is disabled
    assert_equal('chat_disabled', chat.customer_state[:state])
    assert_equal('chat_disabled', Chat.agent_state(agent1.id)[:state])
    Setting.set('chat', true)

    # check customer state
    assert_equal('offline', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(0, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    # set agent 1 to active
    chat_agent1 = Chat::Agent.create_or_update(
      active: true,
      concurrent: 4,
      updated_by_id: agent1.id,
      created_by_id: agent1.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(0, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start session
    chat_session1 = Chat::Session.create(
      chat_id: chat.id,
      user_id: agent1.id,
    )
    assert(chat_session1.session_id)

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(3, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # activate second agent
    chat_agent2 = Chat::Agent.create_or_update(
      active: true,
      concurrent: 2,
      updated_by_id: agent2.id,
      created_by_id: agent2.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(5, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(1, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(5, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start next chat
    chat_session2 = Chat::Session.create(
      chat_id: chat.id,
    )

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(2, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(2, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(4, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # start new chats
    chat_session3 = Chat::Session.create(
      chat_id: chat.id,
    )
    chat_session4 = Chat::Session.create(
      chat_id: chat.id,
    )
    chat_session5 = Chat::Session.create(
      chat_id: chat.id,
    )
    chat_session6 = Chat::Session.create(
      chat_id: chat.id,
    )

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(6, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(6, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    chat_session6.user_id = agent1.id
    chat_session6.state = 'running'
    chat_session6.save

    Chat::Message.create(
      chat_session_id: chat_session6.id,
      content: 'message 1',
      created_by_id: agent1.id,
    )
    sleep 1
    Chat::Message.create(
      chat_session_id: chat_session6.id,
      content: 'message 2',
      created_by_id: agent1.id,
    )
    sleep 1
    Chat::Message.create(
      chat_session_id: chat_session6.id,
      content: 'message 3',
      created_by_id: agent1.id,
    )
    sleep 1
    Chat::Message.create(
      chat_session_id: chat_session6.id,
      content: 'message 4',
      created_by_id: nil,
    )

    # check customer state
    customer_state = chat.customer_state
    assert_equal('no_seats_available', customer_state[:state])
    assert_equal(5, customer_state[:queue])

    # customer chat state
    customer_state = chat.customer_state(chat_session6.session_id)
    assert_equal('reconnect', customer_state[:state])
    assert(customer_state[:session])
    assert_equal(Array, customer_state[:session].class)
    assert_equal('message 1', customer_state[:session][0]['content'])
    assert_equal('message 2', customer_state[:session][1]['content'])
    assert_equal('message 3', customer_state[:session][2]['content'])
    assert_equal('message 4', customer_state[:session][3]['content'])
    assert_equal('Notification Agent1', customer_state[:agent][:name])
    assert_equal(nil, customer_state[:agent][:avatar])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal(Array, agent_state[:active_sessions].class)
    assert_equal(chat.id, agent_state[:active_sessions][0]['chat_id'])
    assert_equal(agent1.id, agent_state[:active_sessions][0]['user_id'])
    assert(agent_state[:active_sessions][0]['messages'])
    assert_equal(Array, agent_state[:active_sessions][0]['messages'].class)
    assert_equal('message 1', agent_state[:active_sessions][0]['messages'][0]['content'])
    assert_equal('message 2', agent_state[:active_sessions][0]['messages'][1]['content'])
    assert_equal('message 3', agent_state[:active_sessions][0]['messages'][2]['content'])
    assert_equal('message 4', agent_state[:active_sessions][0]['messages'][3]['content'])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(0, agent_state[:seads_available])
    assert_equal(6, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    chat_agent2.active = false
    chat_agent2.save

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])
    assert_equal(5, chat.customer_state[:queue])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal(Array, agent_state[:active_sessions].class)
    assert_equal(chat.id, agent_state[:active_sessions][0]['chat_id'])
    assert_equal(agent1.id, agent_state[:active_sessions][0]['user_id'])
    assert(agent_state[:active_sessions][0]['messages'])
    assert_equal(Array, agent_state[:active_sessions][0]['messages'].class)
    assert_equal('message 1', agent_state[:active_sessions][0]['messages'][0]['content'])
    assert_equal('message 2', agent_state[:active_sessions][0]['messages'][1]['content'])
    assert_equal('message 3', agent_state[:active_sessions][0]['messages'][2]['content'])
    assert_equal('message 4', agent_state[:active_sessions][0]['messages'][3]['content'])
    assert_equal(-2, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(1, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-2, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    chat_session6.state = 'closed'
    chat_session6.save

    # check customer state
    assert_equal('no_seats_available', chat.customer_state[:state])
    assert_equal(5, chat.customer_state[:queue])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(5, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(-1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

    chat_session5.destroy
    chat_session4.destroy

    # check customer state
    assert_equal('online', chat.customer_state[:state])

    # check agent1 state
    agent_state = Chat.agent_state_with_sessions(agent1.id)
    assert_equal(3, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(true, agent_state[:active])

    # check agent2 state
    agent_state = Chat.agent_state_with_sessions(agent2.id)
    assert_equal(3, agent_state[:waiting_chat_count])
    assert_equal(0, agent_state[:running_chat_count])
    assert_equal([], agent_state[:active_sessions])
    assert_equal(1, agent_state[:seads_available])
    assert_equal(4, agent_state[:seads_total])
    assert_equal(false, agent_state[:active])

  end

end
