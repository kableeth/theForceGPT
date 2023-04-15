import { LightningElement, wire, track } from 'lwc';
import getMessages from '@salesforce/apex/ChatMessageController.getMessages';

export default class ChatComponent extends LightningElement {
    @track messages = [];

    @wire(getMessages)
    loadMessages({ error, data }) {
        if (data) {
            this.messages = data.map(message => {
                const isInbound = message.Sender_Type__c === 'Inbound';
                const containerClass = isInbound ? 'slds-chat-listitem slds-chat-listitem_inbound' : 'slds-chat-listitem slds-chat-listitem_outbound';
                const messageClass = isInbound ? 'slds-chat-message__text slds-chat-message__text_inbound' : 'slds-chat-message__text slds-chat-message__text_outbound';
                const showAvatar = containerClass === 'slds-chat-listitem slds-chat-listitem_inbound';
                const senderInitials = message.Owner.Name.slice(0, 2).toUpperCase();
                const timestamp = new Date(message.CreatedDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                return {
                    Id: message.Id,
                    containerClass: containerClass,
                    messageClass: messageClass,
                    showAvatar: showAvatar,
                    senderName: message.Owner.Name,
                    senderInitials: senderInitials,
                    messageText: message.Message__c,
                    timestamp: timestamp,
                    ariaLabel: `said ${message.Owner.Name} at ${timestamp}`
                };
            });
        } else if (error) {
            console.error
        }
    }
}
