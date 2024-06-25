import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateAndStorePDF from '@salesforce/apex/GoogleDriveService.generateAndStorePDF';

export default class GenerateAndStorePDFButton extends LightningElement {
    @api recordId;

    generateAndStorePDF() {
        generateAndStorePDF({ invoiceId: this.recordId })
            .then(result => {
                this.showToast('Success', 'PDF Generated and Stored Successfully', 'success');
                console.log('PDF Generated and Stored:', result);
            })
            .catch(error => {
                this.showToast('Error', 'Error Generating or Storing PDF: ' + error.body.message, 'error');
                console.error('Error:', error);
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}