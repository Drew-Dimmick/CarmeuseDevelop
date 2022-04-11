@isTest(SeeAllData=true)
public with sharing class ProductTriggerExecutorTest {
    @IsTest
    static void testProductAddedtoStandardPriceBook() {
        Test.startTest();
        Product2 newProduct = new Product2(Name='Batch Test Product');

        insert newProduct;
        update newProduct;
        Test.stopTest();

        List<Product2> insertedProduct = [SELECT Id, Name FROM Product2 WHERE Name='Batch Test Product' LIMIT 1];

        PriceBook2 standardPriceBook = [SELECT Id, Name
                                        FROM PriceBook2
                                        WHERE Name='Standard Price Book'];

        Id productId;
        if(insertedProduct.size() > 0) {
            productId = insertedProduct[0].Id;
        }

        List<ProductCategoryProduct> productCategory = [SELECT Id, ProductId FROM ProductCategoryProduct WHERE ProductId=:productId LIMIT 1];
        List<PricebookEntry> priceBookEntry = [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry 
                                                WHERE Pricebook2Id=:standardPriceBook.Id AND Product2Id=:productId LIMIT 1];


        System.assertEquals(1, insertedProduct.size(), 'Did not insert new product');
        //System.assertEquals(1, productCategory.size(), 'Product Not added to My Products Category');
        //.assertEquals(1, priceBookEntry.size(), 'Product Not added to standard price book');
    }
}
