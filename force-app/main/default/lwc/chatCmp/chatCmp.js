import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMessages from '@salesforce/apex/ChatMessageController.getMessages';
import sendPrompt from '@salesforce/apex/ChatMessageController.sendPrompt';
import { createRecord } from 'lightning/uiRecordApi'; // Import createRecord
import OPEN_AI_MESSAGE_OBJECT from '@salesforce/schema/Open_AI_Message__c';

export default class ChatComponent extends LightningElement {
    @api recordId;
    @track messages = [];
    searchKey = '';

    wiredMessages;

    @wire(getMessages)
    async loadMessages(result) {
        this.wiredMessagesResult = result;
        const { data, error } = result;
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
            this.messages = this.messages.reverse();    
        } else if (error) {
            console.error
        }
    }

    handleKeyChange(event) {
        this.searchKey = event.target.value;
    }

    handleSend() { // Make the method async
        // Create an OpenAI_Message__c record
        const openaiMessageFields = {
            Message__c: this.searchKey,
            Sender_Type__c: 'outbound'
        };
        const recordInput = {
            apiName: OPEN_AI_MESSAGE_OBJECT.objectApiName,
            fields: openaiMessageFields
        };

        try {
            console.log('before send prmpt.')   
            createRecord(recordInput); // Create the OpenAI_Message__c record
            console.log('before send prmpt.')
            sendPrompt({ prompt: this.searchKey, recordId: this.recordId });
            console.log('after send prmpt.'); // Send the prompt
            this.searchKey = '';
            this.loadMessages();
        } catch (error) {
            console.error('Error sending prompt:', error);
        }
    }
}
