import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
// import LLM "mo:llm"; // Uncomment and adjust if you have a real LLM module

actor {

  // Data types
  type PhoneNumber = Text;

  type ChatMessage = {
    role : Text;
    content : Text;
  };

  type UserHistory = {
    messages : [ChatMessage];
  };

  // Stable storage for persistence across upgrades
  stable var chatEntries : [(PhoneNumber, UserHistory)] = [];

  // In-memory HashMap for fast access
  let chatDB = HashMap.HashMap<PhoneNumber, UserHistory>(10, Text.equal, Text.hash);

  // Restore HashMap from stable storage after upgrade
  system func postupgrade() {
    for ((phone, history) in chatEntries.vals()) {
      chatDB.put(phone, history);
    };
    chatEntries := [];
  };

  // Save HashMap to stable storage before upgrade
  system func preupgrade() {
    chatEntries := Iter.toArray(chatDB.entries());
  };

  // Add a new message to the user's history
  func updateUserHistory(phone : PhoneNumber, msg : ChatMessage) {
    let history = switch (chatDB.get(phone)) {
      case (?existing) existing.messages;
      case null [];
    };

    let updated = {
      messages = Array.append(history, [msg]);
    };

    chatDB.put(phone, updated);
  };

  // Public: Send message from user (simulate WhatsApp message)
  public shared func sendMessage(phone : PhoneNumber, userMsg : Text) : async Text {
    // Add user message
    updateUserHistory(phone, { role = "user"; content = userMsg });

    // Prepare messages for LLM
    /*
    let chatMessages : [LLM.ChatMessage] = switch (chatDB.get(phone)) {
      case (?history) history.messages
        |> Array.map<ChatMessage, LLM.ChatMessage>(func (m) {
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

    let response = await LLM.chat(#Llama3_1_8B).withMessages(chatMessages).send();

    let botReply = switch (response.message.content) {
      case (?text) text;
      case null "Sorry, I didn’t understand that.";
    };
    */

    // For demonstration, just echo the user message
    let botReply = "Echo: " # userMsg;

    // Save bot reply
    updateUserHistory(phone, { role = "assistant"; content = botReply });

    return botReply;
  };

  // Public: Retrieve full message history
  public query func getHistory(phone : PhoneNumber) : async [ChatMessage] {
    switch (chatDB.get(phone)) {
      case (?history) history.messages;
      case null [];
    }
  };

  // Optional: Clear user chat history
  public shared func clearHistory(phone : PhoneNumber) : async Text {
    chatDB.delete(phone);
    return "History cleared for " # phone;
  };
};