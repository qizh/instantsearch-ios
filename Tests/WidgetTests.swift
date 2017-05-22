//
//  WidgetTests.swift
//  WidgetTests
//
//  Copyright © 2016 Algolia. All rights reserved.
//

import XCTest
@testable import InstantSearch
@testable import InstantSearchCore
import AlgoliaSearch

class WidgetTests: XCTestCase {

    var instantSearch: InstantSearch!
    private let ALGOLIA_APP_ID = "latency"
    private let ALGOLIA_INDEX_NAME = "bestbuy_promo"
    private let ALGOLIA_API_KEY = "1f6fd3a6fb973cb08419fe7d288fa4db"
    private let facetResults = [
        FacetValue(value: "Movies & TV Shows", count: 1574),
        FacetValue(value: "Cell Phone Cases & Clips", count: 572),
        FacetValue(value: "Flat-Panel TVs", count: 190),
        FacetValue(value: "Headphones", count: 188),
        FacetValue(value: "iPad Cases, Covers & Sleeves", count: 165),
        FacetValue(value: "Facet Refinement New Value", count: 0)
    ]
    var expectation: XCTestExpectation!
    var defaultRect: CGRect = CGRect(x: 0, y: 0, width: 10, height: 10)


    override func setUp() {
        super.setUp()
        instantSearch = InstantSearch(appID: ALGOLIA_APP_ID, apiKey: ALGOLIA_API_KEY, index: ALGOLIA_INDEX_NAME)
        instantSearch.params.attributesToRetrieve = ["name", "salePrice"]
        instantSearch.params.attributesToHighlight = ["name"]
    }

    override func tearDown() {
        super.tearDown()
    }

    func testAddHitsWidgets() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hitsTableWidget = HitsTableWidget(frame: defaultRect)

        view.addSubview(hitsTableWidget)

        // Make sure that we didn't set the hitsPerPage param before adding the widget.
        XCTAssertNil(instantSearch.searcher.params.hitsPerPage)

        instantSearch.addAllWidgets(in: view, doSearch: false)

        // Make sure params.hitsPerPage was correctly set to the default by just adding the hits widget.
        XCTAssertEqual(instantSearch.searcher.params.hitsPerPage, Constants.Defaults.hitsPerPage)
    }

    func testAddRefinementMenu_defaultCase_FacetAddedToSearcher() {
        // Setup refinement widget along with its controller
        let refinementTableWidget = RefinementTableWidget(frame: defaultRect)
        refinementTableWidget.attribute = "category"

        (refinementTableWidget.viewModel as! RefinementMenuViewModel).facetResults = facetResults

        let refinementController = RefinementController(table: refinementTableWidget)
        refinementTableWidget.dataSource = refinementController
        refinementTableWidget.delegate = refinementController

        XCTAssertNil(instantSearch.params.facets)
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)

        instantSearch.add(widget: refinementTableWidget, doSearch: false)
        XCTAssertEqual(instantSearch.params.facets!, ["category"])
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)

        // Insert dummy row
        refinementTableWidget.beginUpdates()
        refinementTableWidget.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        refinementTableWidget.endUpdates()

        // Select row
        refinementTableWidget.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        refinementController.tableView(refinementTableWidget, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Make sure correct param was added to searcher
        XCTAssertEqual(instantSearch.searcher.params.facetRefinements["category"]![0], FacetRefinement(name: "category", value: "Movies & TV Shows", inclusive: Constants.Defaults.inclusive))
    }

    func testAddRefinementMenu_operatorFalse_FacetAddedToSearcher() {
        // Setup refinement widget along with its controller
        let refinementTableWidget = RefinementTableWidget(frame: defaultRect)
        refinementTableWidget.attribute = "category"
        refinementTableWidget.operator = "and"

        // One way to mock the viewModel (not very nice, but for a first iteration it's good enough)
        (refinementTableWidget.viewModel as! RefinementMenuViewModel).facetResults = facetResults

        let refinementController = RefinementController(table: refinementTableWidget)
        refinementTableWidget.dataSource = refinementController
        refinementTableWidget.delegate = refinementController

        XCTAssertNil(instantSearch.params.facets)
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)

        instantSearch.add(widget: refinementTableWidget)
        XCTAssertEqual(instantSearch.params.facets!, ["category"])
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)

        // Insert dummy row
        refinementTableWidget.beginUpdates()
        refinementTableWidget.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        refinementTableWidget.endUpdates()

        // Select row
        refinementTableWidget.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        refinementController.tableView(refinementTableWidget, didSelectRowAt: IndexPath(row: 0, section: 0))

        // Make sure correct param was added to searcher
        XCTAssertEqual(instantSearch.searcher.params.facetRefinements["category"]![0], FacetRefinement(name: "category", value: "Movies & TV Shows", inclusive: true))
    }

    func testAddSlider_DefaultCase_FacetAddedToSearcher() {
        let slider = SliderWidget(frame: defaultRect)
        slider.attribute = "salePrice"
        slider.minimumValue = 1
        slider.maximumValue = 10
        

        XCTAssertNil(instantSearch.params.numericFilters)
        XCTAssertTrue(instantSearch.params.numericRefinements.isEmpty)
        instantSearch.add(widget: slider)

        // Make sure correct param was added to searcher
        XCTAssertEqual(instantSearch.searcher.params.numericRefinements["salePrice"]![0], NumericRefinement("salePrice", NumericRefinement.Operator.greaterThanOrEqual, NSNumber(value: slider.minimumValue), inclusive: Constants.Defaults.inclusive))

        //TODO: Complete this part. The sendActions was not working for some reason, asked on SO
        // Now change the value of slider
//        slider.setValue(5.5, animated: false)
//        slider.sendActions(for: [.touchUpInside, .touchUpOutside])
//
//        // Make sure of updated value in searcher
//        XCTAssertEqual(instantSearch.searcher.params.numericRefinements["salePrice"]![0], NumericRefinement("salePrice", NumericRefinement.Operator.greaterThanOrEqual, NSNumber(value: 5.5), inclusive: Constants.Defaults.inclusive))
//        
//        // Make sure only the updated one is added, and the old one removed
//        XCTAssertEqual(instantSearch.searcher.params.numericRefinements["salePrice"]!.count, 1)

    }
    
    func testAddslider_CustomAttributes_FacetAddedToSearcher() {
        let slider = SliderWidget(frame: defaultRect)
        slider.attribute = "salePrice"
        slider.operator = "<"
        slider.inclusive = false
        slider.minimumValue = 1
        slider.maximumValue = 10
        slider.setValue(5.5, animated: true)
        
        XCTAssertNil(instantSearch.params.numericFilters)
        XCTAssertTrue(instantSearch.params.numericRefinements.isEmpty)
        instantSearch.add(widget: slider)
        
        // Make sure correct param was added to searcher
        XCTAssertEqual(instantSearch.searcher.params.numericRefinements["salePrice"]![0], NumericRefinement("salePrice", NumericRefinement.Operator.lessThan, NSNumber(value: 5.5), inclusive: false))
    }
    
    func testOneValueSwitchWidget_defaultCase_FacetAddedToSearcher() {
        let oneValueSwitchWidget = OneValueSwitchWidget(frame: defaultRect)
        oneValueSwitchWidget.attribute = "shipping"
        oneValueSwitchWidget.valueOn = "premium"
        
        XCTAssertNil(instantSearch.params.facets)
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)
        
        instantSearch.add(widget: oneValueSwitchWidget)
        XCTAssertNil(instantSearch.params.facets)
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty) // still empty since oneValue Widget should not add
        
        //TODO: emulate changing value and then confirm that facetRefinements got the param
        oneValueSwitchWidget.setOn(true, animated: false)
        oneValueSwitchWidget.sendActions(for: .valueChanged)
        
        XCTAssertEqual(instantSearch.params.facetRefinements["shipping"]![0], FacetRefinement(name: "shipping", value: "premium", inclusive: Constants.Defaults.inclusive))
        
        //TODO: emulate turning off the switch, and confirm that facetRefinements removed the param
    }
    
    func testTwoValueSwitchWidget_defaultCase_FacetAddedToSearcher() {
        let twoValueSwitchWidget = TwoValuesSwitchWidget(frame: defaultRect)
        twoValueSwitchWidget.attribute = "shipping"
        twoValueSwitchWidget.valueOn = "premium"
        twoValueSwitchWidget.valueOff = "standard"
        
        XCTAssertNil(instantSearch.params.facets)
        XCTAssertTrue(instantSearch.params.facetRefinements.isEmpty)
        
        instantSearch.add(widget: twoValueSwitchWidget)
        XCTAssertNil(instantSearch.params.facets)
        XCTAssertEqual(instantSearch.params.facetRefinements["shipping"]![0], FacetRefinement(name: "shipping", value: "standard", inclusive: Constants.Defaults.inclusive))
        
        //TODO: emulate changing value and then confirm that facetRefinements got the param
        //TODO: emulate turning off the switch, and confirm that facetRefinements updated to Off
    }

    // TODO: Need to find a way to expect fatalError to uncomment the below
    // Right now these tests work as expected: the throw a fatal error, but 
    // we need to find a way to catch it.
    
//    func testAddRefinementMenu_NoAttribute_FatalError() {
//        let refinementTableWidget = RefinementTableWidget(frame: defaultRect)
//        instantSearch.add(widget: refinementTableWidget, doSearch: false)
//    }

//    func testAddSlider_NoAttribute_FatalError() {
//        let slider = SliderWidget(frame: defaultRect)
//        instantSearch.add(widget: slider, doSearch: false)
//    }
    
//    func testAddSwitch_NoAttribute_FatalError() {
//        let oneValueSwitchWidget = OneValueSwitchWidget(frame: defaultRect)
//        instantSearch.add(widget: oneValueSwitchWidget)
//    }

//    func testAddRefinementMenu_InvalidOperator_FatalError() {
//        let refinementTableWidget = RefinementTableWidget(frame: defaultRect)
//        refinementTableWidget.attribute = "category"
//        refinementTableWidget.operator = ">>"
//
//        // Spinup the RefinementController to take care of the table
//        let refinementController = RefinementController(table: refinementTableWidget)
//        refinementTableWidget.dataSource = refinementController
//        refinementTableWidget.delegate = refinementController
//
//        instantSearch.add(widget: refinementTableWidget, doSearch: false)
//
//        // Insert dummy row
//        refinementTableWidget.beginUpdates()
//        refinementTableWidget.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//        refinementTableWidget.endUpdates()
//
//        // Select row
//        refinementTableWidget.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
//        refinementController.tableView(refinementTableWidget, didSelectRowAt: IndexPath(row: 0, section: 0))
//    }


    func testAddHitsWidgetsWithCustomParameters() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hitsTableWidget = HitsTableWidget(frame: defaultRect)
        hitsTableWidget.hitsPerPage = 5

        view.addSubview(hitsTableWidget)

        // Make sure that we didn't set the hitsPerPage param before adding the widget.
        XCTAssertNil(instantSearch.searcher.params.hitsPerPage)

        instantSearch.addAllWidgets(in: view, doSearch: false)

        // Make sure params.hitsPerPage was correctly set by just adding the hits widget.
        XCTAssertEqual(instantSearch.searcher.params.hitsPerPage, 5)
    }
}
