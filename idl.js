const idlFactory = ({ IDL }) => {
  return IDL.Service({
    sendMessage: IDL.Func([IDL.Text, IDL.Text], [IDL.Text], []),
    getHistory: IDL.Func([IDL.Text], [IDL.Vec(IDL.Record({
      role: IDL.Text,
      content: IDL.Text
    }))], ['query']),
    clearHistory: IDL.Func([IDL.Text], [IDL.Text], []),
  });
};

module.exports = { idlFactory };
