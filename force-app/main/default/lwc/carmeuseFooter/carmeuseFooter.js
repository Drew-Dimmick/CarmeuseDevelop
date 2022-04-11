import { LightningElement } from 'lwc';
import IMAGES from '@salesforce/resourceUrl/carmeimages';

export default class CarmeuseFooter extends LightningElement {

    carmeuseImageslogo = IMAGES+'/carmuseImages/logo-white.svg';
    instagramLogo = IMAGES+'/carmuseImages/instagram.svg';
    facebookLogo = IMAGES+'/carmuseImages/facebook.svg';
    youtubeLogo = IMAGES+'/carmuseImages/youtube.svg';
    linkedInLogo = IMAGES+'/carmuseImages/linkedin.svg';
}