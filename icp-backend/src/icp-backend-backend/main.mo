import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import LLM "mo:llm";

actor {
  type PhoneNumber = Text;
  type ChatMessage = { role : Text; content : Text };
  type UserHistory = { messages : [ChatMessage] };

  stable var chatEntries : [(PhoneNumber, UserHistory)] = [];
  let chatDB = HashMap.HashMap<PhoneNumber, UserHistory>(10, Text.equal, Text.hash);

  system func postupgrade() {
    for ((phone, history) in chatEntries.vals()) {
      chatDB.put(phone, history);
    };
    chatEntries := [];
  };

  system func preupgrade() {
    chatEntries := Iter.toArray(chatDB.entries());
  };

  func updateUserHistory(phone : PhoneNumber, msg : ChatMessage) {
    let history = switch (chatDB.get(phone)) {
      case (?existing) existing.messages;
      case null [];
    };
    chatDB.put(phone, { messages = Array.append(history, [msg]) });
  };

  public shared func sendMessage(phone : PhoneNumber, userMsg : Text) : async Text {
    updateUserHistory(phone, { role = "user"; content = userMsg });

    let chatMessages : [LLM.ChatMessage] = switch (chatDB.get(phone)) {
      case (?history) history.messages |> Array.map<ChatMessage, LLM.ChatMessage>(func (m) {
        {
          role = switch (m.role) {
            case ("user") #User;
            case ("assistant") #Assistant;
            case _ #User;
          };
          content = m.content;
        }
      });
      case null [];
    };

    let response : LLM.ChatResponse = await LLM.chat(#Llama3_8B).withMessages(chatMessages).send();

    let botReply = switch (response.message.content) {
      case (?text) text;
      case null "Sorry, I didn't get that.";
    };

    updateUserHistory(phone, { role = "assistant"; content = botReply });

    return botReply;
  };

  public query func getHistory(phone : PhoneNumber) : async [ChatMessage] {
    switch (chatDB.get(phone)) {
      case (?history) history.messages;
      case null [];
    }
  };

  public shared func clearHistory(phone : PhoneNumber) : async Text {
    chatDB.delete(phone);
    return "History cleared for " # phone;
  };
};
