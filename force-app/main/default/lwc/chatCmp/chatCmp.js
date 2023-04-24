import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMessages from '@salesforce/apex/ChatMessageController.getMessages';
import sendPrompt from '@salesforce/apex/ChatMessageController.sendPrompt';
import { createRecord } from 'lightning/uiRecordApi';
import OPEN_AI_MESSAGE_OBJECT from '@salesforce/schema/Open_AI_Message__c';
import { CurrentPageReference } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class ChatComponent extends LightningElement {
    @api recordId;
    @wire(CurrentPageReference) 
    pageRef;
    @track messages = [];
    searchKey = '';

    connectedCallback() {
        registerListener('urlChange', this.handleUrlChange, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    handleUrlChange(url) {
        console.log('handleUrlChange');
        const recordIdRegex = /\/lightning\/r\/([^/]+)\/([^/]+)\/view/;
        const match = url.match(recordIdRegex);

        if (match && match.length === 3) {
            this.recordId = match[2];
            this.error = null;
        } else {
            this.recordId = null;
            this.error = 'Not on a record page';
        }
    }

    wiredMessages;

    @wire(getMessages)
    loadMessages(result) {
        this.wiredMessagesResult = result;
        const { error, data } = result;
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
            console.error('error loading message:', error)
        }
    }

    handleKeyChange(event) {
        this.searchKey = event.target.value;
    }

    async handleSend() {
        try {
            console.log('before send prmpt.');
            console.log('recordId: ' + this.recordId);

            // Create outbound message record
            const outboundMessage = {
                apiName: OPEN_AI_MESSAGE_OBJECT.objectApiName,
                fields: {
                    Message__c: this.searchKey,
                    Sender_Type__c: 'Outbound',
                    recordid__c: this.recordId,
                }
            };

            await createRecord(outboundMessage);

            // Send the prompt and retrieve the response
            const response = await sendPrompt({ prompt: this.searchKey, recordId: this.recordId });
            console.log(response);

            // Create inbound message record
            const inboundMessage = {
                apiName: OPEN_AI_MESSAGE_OBJECT.objectApiName,
                fields: {
                    Message__c: response,
                    Sender_Type__c: 'Inbound',
                    recordid__c: this.recordId,
                }
            };

            await createRecord(inboundMessage);

            this.searchKey = '';

            // Refresh messages
            await refreshApex(this.wiredMessagesResult);
            console.log('message logged');

        } catch (error) {
            console.error('Error sending prompt:', error);
        }
    }
    handleKeyUp(event) {
        if (event.keyCode === 13) { // Check if the Enter key was pressed
            this.handleSend(); // Call your desired method
        }
    }
}
