/*----------------------------------------------------------------------
Name:       OrderController.cls
Purpose:    Controller class to fetch Order List and Order Details
------------------------------History----------------------------------
Version     Author          Date                    Detail Description 
-------     -------         --------------          ------------------
1.0         Devang          05-April-2021           Initial Development 
----------------------------------------------------------------------*/
public with sharing class OrderController {

    public static final String ORDER_STATUS_CREATED = 'Created';
    public static final String ORDER_STATUS_PENDING = 'Pending';
    public static final String ORDER_STATUS_RECEIVED = 'Received';
    public static final String ORDER_STATUS_SHIPPED = 'Shipped';
    public static final String ORDER_STATUS_CANCELED = 'Cancelled';
    public static final String ORDER_STATUS_CONFIRMED = 'Confirmed';
    public static final String ORDER_STATUS_FULFILLED = 'Fulfilled';

    @AuraEnabled
    public static OrderDetailWrapper getOrderDetail(Id orderId) {
        //System.debug('step001 orderId' + orderId);
        Id orderSummaryId  = null;
        OrderDetailWrapper orderDetailWrapper = new OrderDetailWrapper();
        Boolean isAccOnHold = false;

        // Fetch Order Summary List based on the logged in user account Id and orginal order Id
        List<OrderSummary> orderSummaryList = OrderUtils.getOrderSummaryById(orderId);
        if(orderSummaryList != null && orderSummaryList.size() > 0){
            for(OrderSummary os : orderSummaryList){
                OrderSummaryDetails osd = new OrderSummaryDetails();
                osd.Id = os.Id;
                orderSummaryId = os.Id;
                osd.originalOrderId = os.OriginalOrderId;
                osd.accountId = os.AccountId;
                osd.totalAmount = os.TotalAmount;
                osd.status = os.Status;
                osd.orderNumber = os.OrderNumber;
                osd.orderedDate = os.OrderedDate;
                osd.accountName =  os.Account.Name;
                osd.poNumber = os.PoNumber;
                osd.description = os.Description;
                osd.billingCity = os.BillingCity;
                osd.billingCountry = os.BillingCountry;
                osd.billingState = os.BillingState;
                osd.billingStreet = os.BillingStreet;
                osd.billingPostalCode = os.BillingPostalCode;
	            osd.orderSummaryRecord = os;
                orderDetailWrapper.orderSummaryDetails = osd;
                isAccOnHold = isAccountOnHold(osd.accountId);
                break;
            }
            
            System.debug('step002 orderSummaryId' + orderSummaryId);
            //Fetch Order Item Summary based on orderSummaryId
            if(orderSummaryId  != null){
                //System.debug('step003 getOrderDeliveryGroupSummaryByOrderSummaryId');
                List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryList = OrderUtils.getOrderDeliveryGroupSummaryByOrderSummaryId(orderSummaryId);
                
                //System.debug('step004 getOrderItemSummaryByOrderSummaryId');
                List<OrderItemSummary> orderItemSummaryList = OrderUtils.getOrderItemSummaryByOrderSummaryId(orderSummaryId);
                List<OrderItemSummaryWrapper> orderItemSummaryWrapperList = new List<OrderItemSummaryWrapper>();
                for(OrderItemSummary ois : orderItemSummaryList){

                    if(String.isNotEmpty(ois.ProductCode)){                    
                        OrderItemSummaryWrapper oisw = getOrderItemSummaryWrapper(orderItemSummaryWrapperList, ois.ProductCode);

                        if(oisw == null){
                            oisw = new OrderItemSummaryWrapper();
                            oisw.orderSummaryId = ois.OrderSummaryId;
                            oisw.product2Id = ois.Product2Id;
                            oisw.productCode = ois.ProductCode;
                            oisw.productName = ois.Product2.Name;
                            oisw.stockKeepingUnit = ois.StockKeepingUnit;
                            oisw.quantity = ois.Quantity;
                            oisw.orderDeliveryGroupSummaryId = ois.OrderDeliveryGroupSummaryId;
                            oisw.materialNumber = ois.Product2.MaterialNumber__c;
                            oisw.orderItemSummaryRecord = ois;

                            // Get List<OrderDeliveryGroupSummaryWrapperHeader> - matching productCode and material number
                            //System.debug('step004a getOrderDeliveryGroupSummaryWrapperHeaderList' + ' oisw.materialNumber ' + oisw.materialNumber);
                            oisw.orderDeliveryGroupSummaryWrapperHeaderList = getOrderDeliveryGroupSummaryWrapperHeaderList(orderDeliveryGroupSummaryList, oisw.materialNumber, oisw.stockKeepingUnit, isAccOnHold);
                            oisw.shipmentTonnage = getProductItemLevelShipmentTonnage(oisw.orderDeliveryGroupSummaryWrapperHeaderList);
                            oisw.totalVolume = getProductItemLevelVolume(oisw.orderDeliveryGroupSummaryWrapperHeaderList);
                            orderItemSummaryWrapperList.add(oisw);
                        } else {
                            oisw.quantity += ois.Quantity;
                            //System.debug('step004b getOrderDeliveryGroupSummaryWrapperHeaderList' + ' for product code ' + ois.ProductCode + ' quantity=' + oisw.quantity);
                        }
                    }
                }
                //System.debug('step005');
                orderDetailWrapper.orderItemSummaryWrapperList = orderItemSummaryWrapperList;                
            }
        }
        //System.debug('Json');
        //System.debug(JSON.serialize(orderDetailWrapper));
        return orderDetailWrapper;
    }


    private static OrderItemSummaryWrapper getOrderItemSummaryWrapper(List<OrderItemSummaryWrapper> orderItemSummaryWrapperList, String productCode){
        for(OrderItemSummaryWrapper oisw : orderItemSummaryWrapperList){
            if(oisw.productCode.equalsIgnoreCase(productCode)){
                return oisw;
            }
        }
        return null;
    }

    private static String getDateStr(Datetime dt){
        if(dt != null){
            return dt.formatGmt('MM/dd/yyyy');
            // Date dt1 = dt.date();
            // return dt1.format();
        }
        return '';
    }

    private static String getDateTimeStr(Datetime dt){
        if(dt != null){
            return dt.format('MM/dd/yyyy, hh:mm');
        }
        return '';
    }

    private static Decimal getProductItemLevelShipmentTonnage(List<OrderDeliveryGroupSummaryWrapperHeader> odgswhl){
        Decimal shipmentTonnage = 0;
        for(OrderDeliveryGroupSummaryWrapperHeader odgswh: odgswhl){
            shipmentTonnage += odgswh.shipmentTonnage;
        }
        return shipmentTonnage;
    }

    private static Decimal getProductItemLevelVolume(List<OrderDeliveryGroupSummaryWrapperHeader> odgswhl){
        Decimal totalVolume = 0;
        for(OrderDeliveryGroupSummaryWrapperHeader odgswh: odgswhl){
            totalVolume += odgswh.totalVolume;
        }
        return totalVolume;
    }

    private static List<OrderDeliveryGroupSummaryWrapperHeader> getOrderDeliveryGroupSummaryWrapperHeaderList(List<OrderDeliveryGroupSummary> orderDeliveryGroupSummaryList, String materialNumber, String stockKeepingUnit, Boolean isAccOnHold ){
        
        //System.debug('step004a1 getOrderDeliveryGroupSummaryWrapperHeaderList ' + ' orderDeliveryGroupSummaryList ' + orderDeliveryGroupSummaryList);
        // Get unique delivery dates for materialNumber
        set<String> desiredDeliveryDateSet = new Set<String>();
        for(OrderDeliveryGroupSummary odgs : orderDeliveryGroupSummaryList){
            System.debug('step004a1* getOrderDeliveryGroupSummaryWrapperHeaderList ' + ' odgs.DesiredDeliveryDate ' + odgs.DesiredDeliveryDate);
            if((String.isNotEmpty(odgs.MaterialNumber__c) && odgs.MaterialNumber__c.equalsIgnoreCase(materialNumber))
                || (String.isNotEmpty(odgs.OriginalMaterialNumber__c) && odgs.OriginalMaterialNumber__c.equalsIgnoreCase(materialNumber))
                ){
                desiredDeliveryDateSet.add(getDateStr(odgs.DesiredDeliveryDate));
            }
        }
        //System.debug('step004a1 getOrderDeliveryGroupSummaryWrapperHeaderList' + ' desiredDeliveryDateSet ' + desiredDeliveryDateSet);

        // prepare level 3 OrderDeliveryGroupSummaryWrapperHeader list for each delivery date
        List<OrderDeliveryGroupSummaryWrapperHeader> odgswhl = new List<OrderDeliveryGroupSummaryWrapperHeader>();
        for (String s : desiredDeliveryDateSet) {
            OrderDeliveryGroupSummaryWrapperHeader odgswh = new OrderDeliveryGroupSummaryWrapperHeader(); 
            odgswh.desiredDeliveryDateStr = s;
            odgswh.materialNumber = materialNumber;
            odgswh.stockKeepingUnit = stockKeepingUnit;
            odgswh.quantity = 0;
            odgswh.cancelledQuantity = 0;
            odgswh.shipmentTonnage = 0;
            odgswh.totalVolume = 0;
            odgswhl.add(odgswh);
        }   
        
        //System.debug('step004a2 getOrderDeliveryGroupSummaryWrapperHeaderList' + ' odgswhl ' + odgswhl.size());
                        
        // loop through header record based on prodouct code and date
        for(OrderDeliveryGroupSummaryWrapperHeader odgswh: odgswhl){

            // prepare level 4 list
            List<OrderDeliveryGroupSummaryWrapper> orderDeliveryGroupSummaryWrapperList = new List<OrderDeliveryGroupSummaryWrapper>();
            Integer i = 0;
            for(OrderDeliveryGroupSummary odgs : orderDeliveryGroupSummaryList){                
                if(((odgs.MaterialNumber__c != null && odgs.MaterialNumber__c.equalsIgnoreCase(odgswh.materialNumber)) || 
                    (odgs.OriginalMaterialNumber__c != null && odgs.OriginalMaterialNumber__c.equalsIgnoreCase(odgswh.materialNumber))) 
                    && (odgswh.DesiredDeliveryDateStr.equalsIgnoreCase(getDateStr(odgs.DesiredDeliveryDate)))){
                      
                    //System.debug('step004a3 getOrderDeliveryGroupSummaryWrapperHeaderList' + ' odgs.DesiredDeliveryDate ' + odgs.DesiredDeliveryDate);
                    //System.debug('step004a3 getOrderDeliveryGroupSummaryWrapperHeaderList' + ' odgs.Quantity__c *' + odgs.Quantity__c + '*' + ' odgswh.quantity =' + odgswh.quantity);
                    odgswh.isAccountOnHold = isAccOnHold;
                    odgswh.quantity += odgs.Quantity__c;
                    if(odgs.ShipmentTonnage__c != null){
                        odgswh.shipmentTonnage += odgs.ShipmentTonnage__c;
                    }
                    if(odgs.ShipmentSize__c != null){
                        odgswh.totalVolume += odgs.ShipmentSize__c;
                    }
                    
                    if(odgs.ShipmentStatus__c != null && (odgs.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CANCELED))){
                        odgswh.cancelledQuantity += odgs.Quantity__c;
                    }  

                    odgswh.deliverToName = odgs.DeliverToName;
                    odgswh.deliverToCity = odgs.DeliverToCity;
                    odgswh.deliverToCountry = odgs.DeliverToCountry;
                    odgswh.deliverToState = odgs.DeliverToState;
                    odgswh.deliverToStreet = odgs.DeliverToStreet;
                    odgswh.deliverToPostalCode = odgs.DeliverToPostalCode;
                    odgswh.shippingMode = odgs.ShipmentSizeType__c;
                    odgswh.shippingModeLabel = odgs.Shipment_Size_Type_Label__c;

                    if(i == 0){                    
                        odgswh.deliveryText =  odgs.DeliveryInstructions;
                        odgswh.poNumber =   odgs.PONumber__c;                 
                        odgswh.loadVolume = odgs.ShipmentSize__c;
                        odgswh.addSampleOrderDeliveryGroupId = odgs.OriginalOrderDeliveryGroupId;
                    }
                    i++;

                    //System.debug('step004a31 getOrderDeliveryGroupSummaryWrapperHeaderList');

                    OrderDeliveryGroupSummaryWrapper odgsw =  new OrderDeliveryGroupSummaryWrapper();   
                
                    odgsw.Id = odgs.Id;
                    odgsw.isAccountOnHold = isAccOnHold;
                    odgsw.accessCode = odgs.AccessCode__c;
                    odgsw.bolNumber = odgs.BOLNumber__c;
                    odgsw.accountExternalNumber = odgs.AccountExternalNumber__c;
                    odgsw.materialNumber = odgs.MaterialNumber__c;
                    odgsw.stockKeepingUnit = stockKeepingUnit;
                    odgsw.desiredDeliveryDate = odgs.DesiredDeliveryDate;                  
                    odgsw.orderDeliveryMethodId = odgs.OrderDeliveryMethodId;
                    odgsw.orderSummaryId = odgs.OrderSummaryId;
                    odgsw.originalOrderDeliveryGroupId = odgs.OriginalOrderDeliveryGroupId;
                    odgsw.quantity = odgs.Quantity__c;
                    odgsw.quoteNumber = odgs.QuoteNumber__c;
                    odgsw.poNumber = odgs.PONumber__c;
                    odgsw.description = odgs.Description;
                    odgsw.deliveryInstructions = odgs.DeliveryInstructions;
                    odgsw.shipmentTonnage = odgs.ShipmentTonnage__c;
                    if(odgs.Cancel_Requested_On__c != null){
                        odgsw.cancelRequestedOn = getDateTimeStr(odgs.Cancel_Requested_On__c); 
                    }
                    if(odgs.Canceled_On__c != null){
                        odgsw.canceledOn = getDateTimeStr(odgs.Canceled_On__c); 
                    }
                    if(odgs.Released_On__c != null){
                        odgsw.releasedOn = getDateTimeStr(odgs.Released_On__c); 
                    }
                    
                    odgsw.cancelRequestedBy = odgs.Cancel_Requested_By__r.FirstName;
                    odgsw.canceledBy = odgs.Canceled_By__r.FirstName;
                    odgsw.releasedBy = odgs.Released_By__r.FirstName;
                    odgsw.isOrderRequestedForCancellation = false;
                    if(String.isNotBlank(odgsw.cancelRequestedBy) && odgsw.cancelRequestedOn != null){
                        odgsw.isOrderRequestedForCancellation = true;
                    }

                    odgsw.isOrderReleasedByCSR = false;
                    if(String.isNotBlank(odgsw.releasedBy) && odgsw.releasedOn != null){
                        odgsw.isOrderReleasedByCSR = true;
                    }

                    odgsw.isOrderCanceledByCSR = false;
                    if(String.isNotBlank(odgsw.canceledBy) && odgsw.canceledOn != null){
                        odgsw.isOrderCanceledByCSR = true;
                        odgsw.isOrderRequestedForCancellation = true;
                    }
                    //System.debug('step004a32 getOrderDeliveryGroupSummaryWrapperHeaderList' + odgsw.cancelRequestedBy);
                    odgsw.shipmentStatus = odgs.ShipmentStatus__c;
                    odgsw.shipmentWeight = odgs.ShipmentWeight__c;
                    odgsw.shipmentSize = odgs.ShipmentSize__c;
                    odgsw.shipmentSizeType = odgs.ShipmentSizeType__c;
                    odgsw.shippingModeLabel = odgs.Shipment_Size_Type_Label__c;

                    if(odgs.ShipmentDateTime__c != null){
                        odgsw.shipmentDateTime = getDateTimeStr(odgs.ShipmentDateTime__c); 
                    }
                    //odgsw.shipmentDateTime = odgs.ShipmentDateTime__c;
                    odgsw.deliverToName	 = odgs.DeliverToName;
                    odgsw.deliverToCity = odgs.DeliverToCity;
                    odgsw.deliverToCountry = odgs.DeliverToCountry;
                    odgsw.deliverToState = odgs.DeliverToState;
                    odgsw.deliverToStreet = odgs.DeliverToStreet;
                    odgsw.deliverToPostalCode = odgs.DeliverToPostalCode;
                    odgsw.isHold = odgs.IsHold__c;
                    odgsw.orderDeliveryGroupSummaryRecord = odgs;
                    if(odgs.ShipmentStatus__c != null 
                        && (odgs.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CANCELED)
                            || odgs.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_SHIPPED)
                            || odgs.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_PENDING)
                        )){
                            odgsw.isCSRButtonToDisplay = false;
                    } else {
                        odgsw.isCSRButtonToDisplay = true;
                    }
                    if(odgs.ShipmentStatus__c != null && (odgs.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CANCELED))){
                        odgsw.isStatusCancelled = true;
                    } else {
                        odgsw.isStatusCancelled = false;
                    }
                    //System.debug('step004a33 getOrderDeliveryGroupSummaryWrapperHeaderList');

                    orderDeliveryGroupSummaryWrapperList.add(odgsw);
                }
            }
            odgswh.orderDeliveryGroupSummaryWrapperList = orderDeliveryGroupSummaryWrapperList;
        }        
        //System.debug('step004a4 getOrderDeliveryGroupSummaryWrapperHeaderList' + ' odgswhl ' + odgswhl);
        return odgswhl;
    }

    public class OrderDetailWrapper{
        @AuraEnabled 
        public Id Id {get; set;}
        @AuraEnabled 
        public String orderNumber {get; set;}
        // Level 1
        // Order Summary
        @AuraEnabled 
        public OrderSummaryDetails orderSummaryDetails {get; set;}
        // Level 2
        // Order Item Summary
        @AuraEnabled 
        public List<OrderItemSummaryWrapper> orderItemSummaryWrapperList {get; set;}    
    }

    public class OrderSummaryDetails{
        @AuraEnabled 
        public Id Id {get; set;}
        @AuraEnabled 
        public Id originalOrderId {get; set;}
        @AuraEnabled 
        public Id accountId {get; set;}
        @AuraEnabled 
        public Decimal totalAmount {get; set;}
        @AuraEnabled 
        public String status {get; set;} 
        @AuraEnabled 
        public String orderNumber {get; set;} 
        @AuraEnabled 
        public Datetime orderedDate {get; set;}
        @AuraEnabled 
        public String accountName {get; set;}  
        @AuraEnabled 
        public String poNumber {get; set;}
        @AuraEnabled 
        public String description {get; set;} 
        @AuraEnabled 
        public String billingCity {get; set;}
        @AuraEnabled 
        public String billingCountry {get; set;}
        @AuraEnabled 
        public String billingState {get; set;}
        @AuraEnabled 
        public String billingStreet {get; set;}
        @AuraEnabled 
        public String billingPostalCode {get; set;}
	    @AuraEnabled
        public OrderSummary orderSummaryRecord {get; set;}
    }

    public class OrderItemSummaryWrapper{
        @AuraEnabled 
        public Id orderSummaryId {get; set;}
        @AuraEnabled 
        public Id product2Id {get; set;}
        @AuraEnabled 
        public String productCode {get; set;}
        @AuraEnabled 
        public String productName {get; set;}
        @AuraEnabled 
        public Decimal shipmentTonnage {get; set;} 
        @AuraEnabled 
        public String stockKeepingUnit {get; set;}
        @AuraEnabled 
        public Decimal quantity {get; set;}         
        @AuraEnabled 
        public String materialNumber {get; set;}
        @AuraEnabled 
        public Id orderDeliveryGroupSummaryId {get; set;}
        @AuraEnabled 
        public Id orderDeliveryGroupId {get; set;}
        @AuraEnabled 
        public Decimal totalVolume {get; set;}
        @AuraEnabled
        public OrderItemSummary orderItemSummaryRecord {get; set;}

        // Level 3
        // Order Delivery Group Summary Wrapper
        @AuraEnabled 
        public List<OrderDeliveryGroupSummaryWrapperHeader> orderDeliveryGroupSummaryWrapperHeaderList {get; set;} 
    }

    
    public class OrderDeliveryGroupSummaryWrapperHeader{
        @AuraEnabled 
        public Boolean isAccountOnHold {get; set;}
        @AuraEnabled 
        public String materialNumber {get; set;}
        @AuraEnabled 
        public String stockKeepingUnit {get; set;}
        @AuraEnabled 
        public Decimal shipmentTonnage {get; set;} 
        @AuraEnabled 
        public String shippingMode {get; set;} 
        @AuraEnabled 
        public String shippingModeLabel {get; set;} 
        @AuraEnabled         
        public Datetime desiredDeliveryDate {get; set;}
        @AuraEnabled 
        public String desiredDeliveryDateStr {get; set;}
        @AuraEnabled 
        public Decimal quantity {get; set;} 
        @AuraEnabled 
        public Decimal cancelledQuantity {get; set;}
        @AuraEnabled 
        public String deliverToName	 {get; set;}
        @AuraEnabled 
        public String deliverToCity	 {get; set;}
        @AuraEnabled 
        public String deliverToCountry {get; set;}
        @AuraEnabled 
        public String deliverToState {get; set;}
        @AuraEnabled 
        public String deliverToStreet {get; set;}
        @AuraEnabled 
        public String deliverToPostalCode {get; set;}
        @AuraEnabled 
        public String deliveryText {get; set;}
        @AuraEnabled 
        public String poNumber {get; set;}
        @AuraEnabled 
        public Id addSampleOrderDeliveryGroupId {get; set;}
        @AuraEnabled 
        public Decimal loadVolume {get; set;}
        @AuraEnabled 
        public Decimal totalVolume {get; set;}

        // Level 4
        // Order Delivery Group Summary 
        @AuraEnabled 
        public List<OrderDeliveryGroupSummaryWrapper> orderDeliveryGroupSummaryWrapperList {get; set;} 
    }


    public class OrderDeliveryGroupSummaryWrapper{
        @AuraEnabled 
        public Id Id {get; set;}
        @AuraEnabled 
        public String accessCode {get; set;}
        @AuraEnabled 
        public String bolNumber {get; set;}
        @AuraEnabled 
        public String accountExternalNumber {get; set;} 
        @AuraEnabled 
        public String materialNumber {get; set;}
        @AuraEnabled 
        public String stockKeepingUnit {get; set;}
        @AuraEnabled 
        public Datetime desiredDeliveryDate {get; set;}
        @AuraEnabled 
        public Id orderDeliveryMethodId {get; set;}
        @AuraEnabled 
        public Id orderSummaryId {get; set;}
        @AuraEnabled 
        public Id originalOrderDeliveryGroupId {get; set;}
        @AuraEnabled 
        public Decimal quantity {get; set;} 
        @AuraEnabled 
        public Decimal cancelledQuantity {get; set;}
        @AuraEnabled 
        public String quoteNumber {get; set;}
        @AuraEnabled 
        public String poNumber {get; set;}
        @AuraEnabled 
        public String description {get; set;} 
        @AuraEnabled 
        public String deliveryInstructions {get; set;} 
        @AuraEnabled 
        public String cancelRequestedOn;
        @AuraEnabled  
        public String cancelRequestedBy;
        @AuraEnabled 
        public String canceledOn;
        @AuraEnabled  
        public String canceledBy;
        @AuraEnabled 
        public String releasedOn;
        @AuraEnabled  
        public String releasedBy;
        @AuraEnabled 
        public Boolean isOrderReleasedByCSR;
        @AuraEnabled 
        public Boolean isOrderCanceledByCSR;
        @AuraEnabled 
        public Boolean isOrderRequestedForCancellation;
        @AuraEnabled 
        public Decimal shipmentTonnage {get; set;} 
        @AuraEnabled 
        public String shipmentStatus {get; set;}
        @AuraEnabled 
        public String shipmentWeight {get; set;}
        @AuraEnabled 
        public Decimal shipmentSize {get; set;} 
        @AuraEnabled 
        public String shipmentSizeType {get; set;}
        @AuraEnabled 
        public String shipmentDateTime {get; set;}
        @AuraEnabled 
        public String deliverToName	 {get; set;}
        @AuraEnabled 
        public String deliverToCity	 {get; set;}
        @AuraEnabled 
        public String deliverToCountry {get; set;}
        @AuraEnabled 
        public String deliverToState {get; set;}
        @AuraEnabled 
        public String deliverToStreet {get; set;}
        @AuraEnabled 
        public String deliverToPostalCode {get; set;}
        @AuraEnabled 
        public String shippingMode {get; set;}
        @AuraEnabled 
        public String shippingModeLabel {get; set;}
        @AuraEnabled 
        public Boolean isAccountOnHold {get; set;}  
        @AuraEnabled 
        public Boolean isHold {get; set;}  
        @AuraEnabled 
        public Boolean isCSRButtonToDisplay {get; set;}  
        @AuraEnabled 
        public Boolean isStatusCancelled {get; set;}   
        @AuraEnabled
        public OrderDeliveryGroupSummary orderDeliveryGroupSummaryRecord {get; set;}
    }

    @TestVisible private static Id getAccountId(){
        Id userId = UserInfo.getUserId();       
        User u = [SELECT Id, ContactId, Email, AccountId FROM User WHERE Id = : userId];
        return u.AccountId;        
    } 

    @TestVisible private static Boolean isAccountOnHold(Id accountId){
        Boolean isHold = false;       
        Account a = [SELECT Id, IsHold__c FROM Account WHERE Id = :accountId];
        if(a != null) {
            isHold = a.IsHold__c;
        }
        return isHold;        
    }

    @AuraEnabled
    public static String getCancelMessageOrderDeliveryGroupByCSR(Id orderDeliveryGroupId) {
        String cancelMessage = '';
        OrderDeliveryGroup odg = [SELECT Id, ShipmentStatus__c, Canceled_On__c, Canceled_By__r.FirstName, Released_On__c, Released_By__r.FirstName 
        FROM OrderDeliveryGroup WHERE Id = :orderDeliveryGroupId];

        if(odg != null && odg.ShipmentStatus__c != null && odg.ShipmentStatus__c.equalsIgnoreCase(ORDER_STATUS_CANCELED)){
            if(String.isNotBlank(odg.Canceled_By__r.FirstName)){
                cancelMessage = 'Canceled by ' + odg.Canceled_By__r.FirstName ;
            }
            if(odg.Canceled_On__c != null){
                cancelMessage = cancelMessage + ' on ' + getDateTimeStr(odg.Canceled_On__c); 
            }
        }
        return cancelMessage;
    }

    @AuraEnabled
    public static String getReleaseMessageOrderDeliveryGroupByCSR(Id orderDeliveryGroupId) {
        String releaseMessage = '';
        OrderDeliveryGroup odg = [SELECT Id, Released_On__c, Released_By__r.FirstName 
        FROM OrderDeliveryGroup WHERE Id = :orderDeliveryGroupId];

        if(odg != null && odg.Released_On__c != null){
            if(String.isNotBlank(odg.Released_By__r.FirstName)){
                releaseMessage = 'Released by ' + odg.Released_By__r.FirstName ;
            }
            if(odg.Released_On__c != null){
                releaseMessage = releaseMessage + ' on ' + getDateTimeStr(odg.Released_On__c); 
            }
        }
        return releaseMessage;
    }

    @AuraEnabled
    public static OrderDeliveryGroup getOrderDeliveryGroupData(Id orderDeliveryGroupId) {
        System.debug('We out here');
        OrderDeliveryGroup odg =  [SELECT Id, DesiredDeliveryDate, QuoteNumber__c, Quantity__c, MaterialNumber__c, OriginalMaterialNumber__c from OrderDeliveryGroup where Id = :orderDeliveryGroupId];
        return odg;
    }

    @AuraEnabled
    public static List<OrderDeliveryGroup> getOrderDeliveryGroupsData(String orderDeliveryGroupsIds) {
        List<Id> records = new List<Id>();
        String[] odgIds = orderDeliveryGroupsIds.split(',');
        for(String id : odgIds) {
            records.add(id);
        }
        List<OrderDeliveryGroup> results =  [SELECT Id, DesiredDeliveryDate, QuoteNumber__c, Quantity__c, MaterialNumber__c, OriginalMaterialNumber__c from OrderDeliveryGroup where Id = :records];
        System.debug('received');
        return results;
    }

    @AuraEnabled
    public static Boolean updateOrderDeliveryGroupByCSR(Id orderDeliveryGroupId, String quoteNumber, String originalMaterialNumber, String materialNumber) {
        Boolean isUpdate = false;
        try {            
            OrderDeliveryGroup odg =  getOrderDeliveryGroupData(orderDeliveryGroupId);
            if(odg != null){
                OrderDeliveryGroup odgUpd = new OrderDeliveryGroup();
                odgUpd.Id = orderDeliveryGroupId;            
                odgUpd.QuoteNumber__c = quoteNumber;
                odgUpd.MaterialNumber__c = materialNumber;
                //retian original material number if csr changes more than once
                if(odg.OriginalMaterialNumber__c == null ||  String.isEmpty(odg.OriginalMaterialNumber__c)){
                    odgUpd.OriginalMaterialNumber__c = originalMaterialNumber;
                }                    
                update odgUpd;
                isUpdate = true;                
            }
            
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;
    }

    @AuraEnabled
    public static Boolean cancelOrderDeliveryGroupByCSR(Id orderDeliveryGroupId) {
        Boolean isUpdate = false;
        try {            
            
            OrderDeliveryGroup odg = new OrderDeliveryGroup();
            odg.Id = orderDeliveryGroupId;            
            odg.ShipmentStatus__c = ORDER_STATUS_CANCELED;
            odg.Canceled_By__c = UserInfo.getUserId();
            odg.Canceled_On__c = DateTime.now();
            update odg;
            isUpdate = true;
            
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;
    }

    @AuraEnabled
    public static Boolean releaseOrderDeliveryGroupByCSR(Id orderDeliveryGroupId) {
        Boolean isUpdate = false;
        try {            
            
            OrderDeliveryGroup odg = new OrderDeliveryGroup();
            odg.Id = orderDeliveryGroupId;
            odg.IsHold__c = false;
            odg.Released_By__c = UserInfo.getUserId();
            odg.Released_On__c = DateTime.now();
            update odg;
            isUpdate = true;
            
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;
    }

    @AuraEnabled
    public static Boolean cancelOrderDeliveryGroupByPortalUser(Id orderDeliveryGroupId, Id orderId) {
        Boolean isUpdate = false;
        try {            
            
            OrderDeliveryGroupSummary odgs = [SELECT Id, OrderSummary.OrderNumber FROM OrderDeliveryGroupSummary where OriginalOrderDeliveryGroupId = :orderDeliveryGroupId];
            OrderDeliveryGroup odg = new OrderDeliveryGroup();
            odg.Id = orderDeliveryGroupId;
            if(odgs != null && odgs.OrderSummary.OrderNumber != null  && String.isNotBlank(odgs.OrderSummary.OrderNumber)){
                odg.OrderSummaryNumber__c = odgs.OrderSummary.OrderNumber;
            }
            odg.Cancel_Requested_By__c = UserInfo.getUserId();
            odg.Cancel_Requested_On__c =  DateTime.now();            
            update odg;
            isUpdate = true;
            
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;
    }

    @AuraEnabled
    public static Boolean updateQuoteNumber(Id orderDeliveryGroupId, String quoteNumber) {
        Boolean isUpdate = false;
        // validate quote number
        // Ensure customer is entitle for this quote
        // get Material Number
        // update quote number and material number
        try {
            OrderDeliveryGroup odg = new OrderDeliveryGroup();
            odg.Id = orderDeliveryGroupId;            
            odg.QuoteNumber__c = quoteNumber;
            update odg;
            isUpdate = true;
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getExtendedEntitlement(Id accountId){
        
        List<String> materialList = new List<String>();
        try {            
            //orderDeliveryGroup odg  = [SELECT AccountExternalNumber__c  FROM orderDeliveryGroup WHERE Id = :orderDeliveryGroupId];
        
            System.debug('step accountId' + accountId);              
            if(accountId != null) {
                      
                List<ExtendedEntitlement__c> eel = [SELECT AccountExtendedEntitlement__c,AccountExternalNumber__c,
                AccountNumber__c,CreatedById,CreatedDate,Id,MaterialNumber__c,Name,Plant_Code__c,
                Price__c,QuoteNumber__c,Selected__c
                FROM ExtendedEntitlement__c
                WHERE AccountExtendedEntitlement__c = :accountId];  
                
                for(ExtendedEntitlement__c e : eel){                    
                    materialList.add(e.QuoteNumber__c  + ' | ' + e.Plant_Code__c + ' | ' +  e.MaterialNumber__c );
                }
            }
          
        } catch (Exception e) {            
            System.Debug(e.getMessage());
        }        
        return materialList;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPlantCode(Id accountId){
        
        List<String> plantCodeList = new List<String>();
        try {            
            //orderDeliveryGroup odg  = [SELECT AccountExternalNumber__c  FROM orderDeliveryGroup WHERE Id = :orderDeliveryGroupId];
        
            System.debug('step accountId' + accountId);              
            if(accountId != null) {
                      
                List<ExtendedEntitlement__c> eel = [SELECT AccountExtendedEntitlement__c,AccountExternalNumber__c,
                AccountNumber__c,MaterialNumber__c,Plant_Code__c,QuoteNumber__c
                FROM ExtendedEntitlement__c
                WHERE AccountExtendedEntitlement__c = :accountId];  
                
                for(ExtendedEntitlement__c e : eel){                    
                    plantCodeList.add(e.QuoteNumber__c  + ' | ' + e.Plant_Code__c);
                }
            }
          
        } catch (Exception e) {            
            System.Debug(e.getMessage());
        }        
        return plantCodeList;
    }

    @AuraEnabled
    public static Boolean updateQuantity(Id orderDeliveryGroupSummaryId, Integer quantity, Date desiredDeliveryDate, String productCode) {
        Boolean isUpdate = false;
        try {
            //Get order summary id, order and desired delivery date
            //Get all order delivery group entry based on order id and desired delivery date.
            //count based on desired delivery date
            //passed qty more than count, add new entry
            //refresh to show new quantity
            isUpdate = true;
          
        } catch(DmlException e) {
            isUpdate = false;
        }
        return isUpdate;      
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountInvoice__c> getUserInvoices(String accountId, String searchKey, String sortBy, String sortDirection, Date startDate, Date endDate) {
        
        String query = 'SELECT Id, Name, Invoice_Number__c, InvoiceDate__c, AccountInvoiceRelation__c FROM AccountInvoice__c WHERE AccountInvoiceRelation__c = :accountId';
        system.debug('query---'+query);
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            query += ' AND Invoice_Number__c LIKE :key';
        }
        if ( startDate != null ) {
            query += ' AND InvoiceDate__c >= :startDate';
        }
        if ( endDate != null ) {
            query += ' AND InvoiceDate__c <= :endDate';
        }
        if ( sortBy != null && sortDirection != null ) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        return Database.query( query );
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getUserOrders(String accountId, String searchKey, String sortBy, String sortDirection, Date startDate, Date endDate) {
        
        String query = 'SELECT Id, Name, ORderNumber, AccountId, EffectiveDate, Status FROM Order WHERE AccountId = :accountId';
        system.debug('query---'+query);
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            query += ' AND 	OrderNumber LIKE :key';
        }
        if ( startDate != null ) {
            query += ' AND EffectiveDate >= :startDate';
        }
        if ( endDate != null ) {
            query += ' AND EffectiveDate <= :endDate';
        }
        if ( sortBy != null && sortDirection != null ) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        return Database.query( query );
    }

    @AuraEnabled(cacheable=true)
    public static List<Order> getUserBOLs(String accountId, String searchKey, String sortBy, String sortDirection, Date startDate, Date endDate) {

        List<Order> orders = [SELECT Id, AccountId FROM Order WHERE AccountId = :accountId];
        Set<Id> orderIds = (new Map<Id,SObject>(orders)).keySet();
        List<OrderDeliveryGroup> odg = [SELECT Id, OrderId, Bill_Of_Lading__c FROM OrderDeliveryGroup WHERE OrderId IN :orderIds];
        Set<Id> bolIds = new Set<Id>();
        for(OrderDeliveryGroup deliveryGroup : odg) {
            bolIds.add(deliveryGroup.Bill_Of_Lading__c);
        }
        // List<OrderDeliveryGroupSummary> odgs = [SELECT Id, OriginalOrderDeliveryGroupId 
        //                                         FROM OrderDeliveryGroupSummary 
        //                                         WHERE OriginalOrderDeliveryGroupId IN :odgIds]; 
        // Set<Id> odgsIds = (new Map<Id,SObject>(odgs)).keySet();
        
        String query = 'SELECT Id, Ac_GI_Date__c, BOL_Number__c, Delivery_Quantity__c, Material_Number__c, Material__c, Account_Number_of_Vendor_or_Creditor__c, Vendor__c FROM Bill_Of_Lading__c WHERE Id IN :bolIds';
        system.debug('query---'+query);
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            query += ' AND BOL_Number__c LIKE :key';
        }
        if ( startDate != null ) {
            query += ' AND Ac_GI_Date__c >= :startDate';
        }
        if ( endDate != null ) {
            query += ' AND Ac_GI_Date__c <= :endDate';
        }
        if ( sortBy != null && sortDirection != null ) {
            query += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        return Database.query( query );
    }

    @AuraEnabled(cacheable=true)
    public static String getPONumber(String productId) {
       
        String poNumber;

        List<PricebookEntry> pbEntry = [SELECT Id, Product2Id, PO_Number__c
                                    FROM PricebookEntry
                                    WHERE Product2Id=:productId];

        for(PricebookEntry pbe : pbEntry) {
            if(pbe.PO_Number__c != null) {
                poNumber = pbe.PO_Number__c;
            }
        }

        return poNumber;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderSummary> getOrderSummaryByOriginalOrderId(Id originalOrderId) {
        System.Debug('Original Order Id: ' + originalOrderId);
        Id ooId = originalOrderId;
        List<OrderSummary> os = [SELECT Id, OrderNumber, OriginalOrderId 
                                FROM OrderSummary
                                WHERE OriginalOrderId=:ooId];
        System.Debug('Order Summary:' + os);
		return os;
	}

    @AuraEnabled(cacheable=true)
    public static Order getOrderByOrderId(Id orderId) {
        System.Debug('Original Order Id: ' + orderId);
        Id oId = orderId;
        Order order = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, OwnerId
                                   FROM Order
                                   WHERE Id=:oId];
        System.Debug('Order Summary:' + order);
		return order;
    }

    @AuraEnabled(cacheable=true)
    public static List<OrderDeliveryGroup> getOrderDeliveryGroupByOrderId(Id orderId) {
        Id oId = orderId;
        List<OrderDeliveryGroup> odgs = [SELECT Id, OrderId, DesiredDeliveryDate, Quantity__c, ShipmentSizeType__c, Shipment_Size_Type_Label__c, ShipmentTonnage__c,
                        AccessCode__c, BOLNumber__c, ShipmentStatus__c, QuoteNumber__c, PONumber__c, AccountExternalNumber__c, 
                        MaterialNumber__c, SplitShipmentId__c, DeliverToAddress, DeliverToName
                      FROM OrderDeliveryGroup
                      WHERE OrderId=:oId];
        
		return odgs;
    }
}