//
//  FoodAppUITests.swift
//  FoodAppUITests
//
//  Created by Rodrigo Celso Gobbi on 11/15/16.
//  Copyright © 2016 Hagen. All rights reserved.
//

import XCTest

class FoodAppUITests: XCTestCase {
    
    func waitForServer(app: XCUIApplication) {
        let exists = NSPredicate(format: "count > 0")
        let tblElement = app.tables.element.cells
        
        expectationForPredicate(exists, evaluatedWithObject: tblElement, handler: nil)
        waitForExpectationsWithTimeout(60) {
            error in XCTAssertNil(error, "server was down")
        }
    }
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCar() {
        let app = XCUIApplication()

        waitForServer(app)
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.collectionViews.cells.elementBoundByIndex(0).images.elementBoundByIndex(0).tap()
        elementsQuery.buttons["stepperAdd"].tap()
        app.buttons["Adicionar na cesta"].tap()
        app.tabBars.buttons["Cesta"].tap()
        
        // check badge value
        var items = app.tabBars.buttons["Cesta"].value as? String
        XCTAssert(items == "2 items", "badge icon invalid")

        // check the number of products
        let qtd = app.tables.cells.elementBoundByIndex(0).childrenMatchingType(.TextField).element.value as? String
        var tableCount = app.tables.cells.count
        XCTAssert(qtd == "2", "number of products incorrect")
        XCTAssert(tableCount == 5, "number of rows incorrect")
        
        app.terminate()
        app.launch()
        waitForServer(app)
        
        // check after reboot
        items = app.tabBars.buttons["Cesta"].value as? String
        XCTAssert(items == "", "badge icon invalid after restart value = \(items)")
        
        app.tabBars.buttons["Cesta"].tap()
        tableCount = app.tables.cells.count
        XCTAssert(tableCount == 0, "number of rows incorrect after restart = \(tableCount)")
        
        app.tabBars.buttons["Cardapio"].tap()
        elementsQuery.collectionViews.cells.elementBoundByIndex(0).images.elementBoundByIndex(0).tap()
        
        let stepperaddButton = app.scrollViews.otherElements.buttons["stepperAdd"]
        for i in 0..<100 {
            if i < 99 {
                XCTAssert(stepperaddButton.enabled == true, "stepper is not enabled")
            }
            stepperaddButton.tap()
        }

        // add max element, chech alert messages
        XCTAssert(stepperaddButton.enabled == false, "stepper is not disabled")
        app.buttons["Adicionar na cesta"].tap()
        
        // cant add more
        elementsQuery.collectionViews.cells.elementBoundByIndex(0).images.elementBoundByIndex(0).tap()
        app.buttons["Adicionar na cesta"].tap()
        let alertTitle = app.alerts.element.label
        XCTAssert(app.alerts.element.label == "Atenção", "wrong alert title = \(alertTitle)")
        
        let alertMsgElement = app.staticTexts["Não é possível adicionar mais que '100' unidades do mesmo produto!"]
        XCTAssert(alertMsgElement.exists == true, "wrong alert msg")
        let okButton = app.alerts["Atenção"].collectionViews.buttons["Ok"]
        okButton.tap()
        
        // remove
        app.navigationBars["FoodApp.NewProductDetailView"].buttons["Inicio"].tap()
        app.tabBars.buttons["Cesta"].tap()
        
        app.tables.cells.elementBoundByIndex(0).swipeLeft()
        app.tables.buttons["Remover"].tap()

        tableCount = app.tables.cells.count
        XCTAssert(tableCount == 0, "number of rows incorrect after restart = \(tableCount)")
    }
    
    func testSendOderWithLoginTest() {
        let app = XCUIApplication()
        
        waitForServer(app)

        // add two elements in the clients car
        let elementsQuery = app.scrollViews.otherElements
        let collectionViewsQuery2 = elementsQuery.collectionViews
        collectionViewsQuery2.elementBoundByIndex(0).images.elementBoundByIndex(0).tap()
        
        let adicionarNaCestaButton = app.buttons["Adicionar na cesta"]
        adicionarNaCestaButton.tap()
        collectionViewsQuery2.elementBoundByIndex(0).images.elementBoundByIndex(1).tap()
        adicionarNaCestaButton.tap()
        
        let tabBarsQuery = app.tabBars
        let cestaButton = tabBarsQuery.buttons["Cesta"]
        cestaButton.tap()
        
        // check table count
        var tableCount = app.tables.cells.count
        XCTAssert(tableCount == 6, "products were not added = \(tableCount)")
        
        // add bookmarks
        tabBarsQuery.buttons["Cardapio"].tap()
        let foodAppNewproductdetailviewNavigationBar = app.navigationBars["FoodApp.NewProductDetailView"]
        elementsQuery.tables.elementAtIndex(0).tap()
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(0).childrenMatchingType(.Image).element.tap()
        let starButton = elementsQuery.buttons["star"]
        starButton.tap()
        
        let voltarButton = foodAppNewproductdetailviewNavigationBar.buttons["Voltar"]
        voltarButton.tap()
        collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(1).childrenMatchingType(.Image).element.tap()
        starButton.tap()
        voltarButton.tap()
        

        tabBarsQuery.buttons["Favoritos"].tap()
        tableCount = app.tables.cells.count
        XCTAssert(tableCount == 2, "incorrect number of bookmarks = \(tableCount)")

        var tablesQuery = app.tables
        tablesQuery.cells.elementAtIndex(0).buttons["Cesta"].tap()
        tablesQuery.cells.elementAtIndex(1).buttons["Cesta"].tap()

        // check if elements were added
        cestaButton.tap()
        tableCount = app.tables.cells.count
        XCTAssert(tableCount == 8, "products were not added through bookmarks = \(tableCount)")
        
        tablesQuery = app.tables
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(4).childrenMatchingType(.TextField).element.tap()
        app.toolbars.buttons["OK"].tap()
        app.navigationBars["Cesta"].buttons["Prosseguir"].tap()
        
        XCUIApplication().navigationBars["Cesta"].buttons["Finalizar"].tap()
        
        // login
        app.textFields["Usuário"].tap()
        app.textFields["Usuário"].typeText("teste@xxx.com.br")
        app.buttons["Next:"].tap()
        app.secureTextFields["Senha"].tap()
        app.secureTextFields["Senha"].typeText("123456")
        app.buttons["Go"].tap()
        
        // order
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(0).childrenMatchingType(.StaticText).element.tap()
        app.sheets["Qual a forma de pagamento?"].collectionViews.buttons["Cartão de Crédito"].tap()
        
        //FIXME recording over eureka is not working.
        app.tables.staticTexts["Informe o horário"].tap()
        app.sheets["Escolha o horário desejado"].collectionViews.buttons["16h - 18h"].tap()
        
        tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(3).childrenMatchingType(.StaticText).element.tap()
        app.sheets["Qual endereço você quer utilizar?"].collectionViews.buttons["Rua Teste App"].tap()
        
        // send
        app.navigationBars["Finalizando Pedido"].buttons["Enviar"].tap()
        app.alerts["Atenção"].collectionViews.buttons["Ok"].tap()
    }
}
