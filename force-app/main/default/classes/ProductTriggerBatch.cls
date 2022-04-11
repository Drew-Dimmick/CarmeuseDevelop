global class ProductTriggerBatch implements Database.Batchable<sObject> {
    global List<Product2> productList = new List<Product2>();

    global ProductTriggerBatch(List<Product2> productList) {
        this.productList = productList;
    }

    global List<Product2> start(Database.BatchableContext BC) {
        
        return productList; 
    }
     
    global void execute(Database.BatchableContext bc, List<Product2> scope) {
        List<ProductCategoryProduct> newProducts = new List<ProductCategoryProduct>();
        List<PricebookEntry> newStandardPBEntries = new List<PricebookEntry>();

        List<ProductCategory> productsCategory = [SELECT Id, Name
                                            FROM ProductCategory
                                            WHERE Name='My Products' LIMIT 1];

        List<PriceBook2> standardPriceBook = [SELECT Id, Name
                                        FROM PriceBook2
                                        WHERE Name='Standard Price Book' LIMIT 1];

        Id categoryId;
        if(productsCategory.size() > 0) {
            categoryId = productsCategory[0].Id;
        }

        Id priceBookId;
        if(standardPriceBook.size() > 0) {
            priceBookId = standardPriceBook[0].Id;
        }
        
        for(Product2 product : scope) {
            ProductCategoryProduct pcp = new ProductCategoryProduct();
            pcp.ProductId = product.Id;
            pcp.ProductCategoryId = categoryId;

            newProducts.add(pcp);

            PricebookEntry pbEntry = new PricebookEntry();
            pbEntry.Pricebook2Id = priceBookId;
            pbEntry.Product2Id = product.Id;
            pbEntry.IsActive = true;
            pbEntry.UnitPrice = 930;

            newStandardPBEntries.add(pbEntry);
        }

        insert newProducts;
        insert newStandardPBEntries;
    }   
     
    global void finish(Database.BatchableContext BC) {
        
    }
}

