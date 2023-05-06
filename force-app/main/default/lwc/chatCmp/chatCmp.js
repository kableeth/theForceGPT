import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getMessages from '@salesforce/apex/ChatMessageController.getMessages';
import sendPrompt from '@salesforce/apex/ChatMessageController.sendPrompt';
import { createRecord } from 'lightning/uiRecordApi';
import OPEN_AI_MESSAGE_OBJECT from '@salesforce/schema/Open_AI_Message__c';

export default class ChatComponent extends LightningElement {
    _recordId;
    
    @track messages = [];
    searchKey = '';
    prompt = '';
    isTyping = false;

    @api recordId;
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        console.log('recordId changed:', this._recordId);
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
        console.log('before send prompt.');
        console.log('recordId: ' + this.recordId);
        this.prompt = this.searchKey;
        this.searchKey = '';
        this.isTyping = true;

        // Create outbound message record
        const outboundMessage = {
            apiName: OPEN_AI_MESSAGE_OBJECT.objectApiName,
            fields: {
                Message__c: this.prompt,
                Sender_Type__c: 'Outbound',
                recordid__c: this.recordId,
            }
        };

        await createRecord(outboundMessage);

        // Scroll to the bottom of the messages container again
        this.scrollToBottom();

        // Refresh messages after creating the outbound message
        await refreshApex(this.wiredMessagesResult);

        // Send the prompt and retrieve the response
        const response = await sendPrompt({ prompt: this.prompt, recordId: this.recordId });
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
        this.scrollToBottom();
        
        await createRecord(inboundMessage);

        // Refresh messages again after creating the inbound message
        await refreshApex(this.wiredMessagesResult);

        // Scroll to the bottom of the messages container again
        this.scrollToBottom();

        this.isTyping = false;
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
    scrollToBottom() {
    const container = this.template.querySelector('[data-id="messages-container"]');
    if (container) {
        container.scrollTop = container.scrollHeight;
    }
}
}
