import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import getQuoteData from '@salesforce/apex/QuoteController.getQuoteData';
import updateQuoteStatus from '@salesforce/apex/QuoteController.updateQuoteStatus';

const QUOTE_LINE_ITEM_FIELDS = [
    { label: 'Product Name', fieldName: 'Product_Name__c' },
    { label: 'Unit Price', fieldName: 'UnitPrice'},
    { label: 'Discount', fieldName: 'Discount' },
    { label: 'Total Price', fieldName: 'TotalPrice' },
];

export default class QuoteApproval extends LightningElement {
    @api recordId;
    @track quoteData = {};
    @track isDisabled = false;

    quoteLineItemColumns = QUOTE_LINE_ITEM_FIELDS.map(field => ({
        label: field.label,
        fieldName: field.fieldName,
        type: 'text',
    }));

    @wire(CurrentPageReference)
    getPageReferenceParameters(pageReference) {
        if (pageReference) {
            this.recordId = pageReference.state.quoteId;
        }
    }

    get isQuoteFinalized() {
        return this.quoteData.status === 'Accepted' || this.quoteData.status === 'Denied';
    }

    get quoteStatusMessage() {
        if (this.quoteData.status === 'Accepted') {
            return 'Quote Accepted';
        } else if (this.quoteData.status === 'Denied') {
            return 'Quote Denied';
        }
        return '';
    }

    @wire(getQuoteData, { quoteId: '$recordId' })
    wiredQuoteData({ error, data }) {
        if (data) {
            this.quoteData = data;
            console.log('Quote Data:', data);
        } else if (error) {
            console.error('Error fetching quote data:', error);
        }
    }

    handleApprove() {
        this.updateQuoteStatus('Accepted');
    }

    handleReject() {
        this.updateQuoteStatus('Denied');
    }

    updateQuoteStatus(newStatus) {
        this.isDisabled = true;
        updateQuoteStatus({ quoteId: this.recordId, newStatus: newStatus })
            .then(() => {
                getRecordNotifyChange([{ recordId: this.recordId }]);
                this.quoteData = { ...this.quoteData, status: newStatus };
                console.log('Quote status updated to:', newStatus);
            })
            .catch(error => {
                this.isDisabled = false;
                console.error('Error updating quote status:', error);
            });
    }
}