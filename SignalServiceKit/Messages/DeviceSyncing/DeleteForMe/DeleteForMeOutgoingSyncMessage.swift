//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import LibSignalClient

/// Represents a sync message, being sent from this device, related to "delete
/// for me" actions.
///
/// - SeeAlso ``DeleteForMeOutgoingSyncMessageManager``
@objc(DeleteForMeOutgoingSyncMessage)
class DeleteForMeOutgoingSyncMessage: OWSOutgoingSyncMessage {
    typealias Outgoing = DeleteForMeSyncMessage.Outgoing

    struct Contents: Codable {
        let messageDeletes: [Outgoing.MessageDeletes]
        let conversationDeletes: [Outgoing.ConversationDelete]
        let localOnlyConversationDelete: [Outgoing.LocalOnlyConversationDelete]

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMe {
            let protoBuilder = SSKProtoSyncMessageDeleteForMe.builder()
            protoBuilder.setMessageDeletes(messageDeletes.map { $0.asProto })
            protoBuilder.setConversationDeletes(conversationDeletes.map { $0.asProto })
            protoBuilder.setLocalOnlyConversationDeletes(localOnlyConversationDelete.map { $0.asProto })
            return protoBuilder.buildInfallibly()
        }
    }

    /// A JSON-serialized ``Contents`` struct.
    ///
    /// - Important: The ObjC name must not change, for Mantle compatibility.
    /// - Note
    /// Nullability is intentional, since Mantle will set this property via its
    /// reflection-based `init(coder:)` when we call `super.init(coder:)`.
    @objc(contents)
    private(set) var contentsData: Data!

    init?(
        contents: Contents,
        thread: TSThread,
        tx: SDSAnyReadTransaction
    ) {
        do {
            self.contentsData = try JSONEncoder().encode(contents)
        } catch {
            owsFailDebug("Failed to encode sync message contents!")
            return nil
        }

        super.init(thread: thread, transaction: tx)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    required init(dictionary dictionaryValue: [String: Any]!) throws {
        try super.init(dictionary: dictionaryValue)
    }

    override public var isUrgent: Bool { false }

    override public func syncMessageBuilder(transaction: SDSAnyReadTransaction) -> SSKProtoSyncMessageBuilder? {
        let contents: Contents
        do {
            contents = try JSONDecoder().decode(Contents.self, from: contentsData)
        } catch let error {
            owsFailDebug("Failed to decode serialized sync message contents! \(error)")
            return nil
        }

        let syncMessageBuilder = SSKProtoSyncMessage.builder()
        syncMessageBuilder.setDeleteForMe(contents.asProto)
        return syncMessageBuilder
    }
}

// MARK: -

extension DeleteForMeSyncMessage.Outgoing {
    enum ConversationIdentifier: Codable {
        case threadAci(aci: String)
        case threadE164(e164: String)
        case threadGroupId(groupId: Data)

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMeConversationIdentifier {
            let protoBuilder = SSKProtoSyncMessageDeleteForMeConversationIdentifier.builder()
            switch self {
            case .threadAci(let aci): protoBuilder.setThreadAci(aci)
            case .threadE164(let e164): protoBuilder.setThreadE164(e164)
            case .threadGroupId(let groupId): protoBuilder.setThreadGroupID(groupId)
            }
            return protoBuilder.buildInfallibly()
        }
    }

    struct AddressableMessage: Codable {
        enum Author: Codable {
            case aci(aci: String)
            case e164(e164: String)
        }

        let author: Author
        let sentTimestamp: UInt64

        init?(incomingMessage: TSIncomingMessage) {
            if let authorAci = incomingMessage.authorAddress.aci {
                author = .aci(aci: authorAci.serviceIdUppercaseString)
            } else if let authorE164 = incomingMessage.authorAddress.e164 {
                author = .e164(e164: authorE164.stringValue)
            } else {
                return nil
            }

            sentTimestamp = incomingMessage.timestamp
        }

        init(outgoingMessage: TSOutgoingMessage, localIdentifiers: LocalIdentifiers) {
            author = .aci(aci: localIdentifiers.aci.serviceIdUppercaseString)
            sentTimestamp = outgoingMessage.timestamp
        }

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMeAddressableMessage {
            let protoBuilder = SSKProtoSyncMessageDeleteForMeAddressableMessage.builder()
            protoBuilder.setSentTimestamp(sentTimestamp)
            switch author {
            case .aci(let aci): protoBuilder.setAuthorAci(aci)
            case .e164(let e164): protoBuilder.setAuthorE164(e164)
            }
            return protoBuilder.buildInfallibly()
        }
    }

    struct MessageDeletes: Codable {
        let conversationIdentifier: ConversationIdentifier
        let addressableMessages: [AddressableMessage]

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMeMessageDeletes {
            let protoBuilder = SSKProtoSyncMessageDeleteForMeMessageDeletes.builder()
            protoBuilder.setConversation(conversationIdentifier.asProto)
            protoBuilder.setMessages(addressableMessages.map { $0.asProto })
            return protoBuilder.buildInfallibly()
        }
    }

    struct ConversationDelete: Codable {
        let conversationIdentifier: ConversationIdentifier
        let mostRecentAddressableMessages: [AddressableMessage]
        let isFullDelete: Bool

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMeConversationDelete {
            let protoBuilder = SSKProtoSyncMessageDeleteForMeConversationDelete.builder()
            protoBuilder.setConversation(conversationIdentifier.asProto)
            protoBuilder.setMostRecentMessages(mostRecentAddressableMessages.map { $0.asProto })
            protoBuilder.setIsFullDelete(isFullDelete)
            return protoBuilder.buildInfallibly()
        }
    }

    struct LocalOnlyConversationDelete: Codable {
        let conversationIdentifier: ConversationIdentifier

        fileprivate var asProto: SSKProtoSyncMessageDeleteForMeLocalOnlyConversationDelete {
            let protoBuilder = SSKProtoSyncMessageDeleteForMeLocalOnlyConversationDelete.builder()
            protoBuilder.setConversation(conversationIdentifier.asProto)
            return protoBuilder.buildInfallibly()
        }
    }
}
