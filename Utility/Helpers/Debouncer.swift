//
//  Debouncer.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 5/22/26.
//

//HOW TO USE
/*
 @Observable
 final class SearchViewModel {
	 var searchText = ""
	 private let debouncedSearch: Debouncer<String>
	 
	 init() {
	 self.debouncedSearch = Debouncer({ [weak self] query in
	 await self?.performSearch(query)
	 }, for: .milliseconds(350))
	 }
	 
	 func textChanged(to newText: String) {
		debouncedSearch(newText)
	 }
	 
	 private func performSearch(_ query: String) async {
	 // Network call, etc.
	 }
 }
 */

actor Debouncer<each Parameter: Sendable>: Sendable {
    private let action: @Sendable (repeat each Parameter) async -> Void
    private let delay: Duration
    private var task: Task<Void, Never>?
    
    init(
        _ action: @Sendable @escaping (repeat each Parameter) async -> Void,
        for delay: Duration
    ) {
        self.action = action
        self.delay = delay
    }
    
    func callAsFunction(_ parameter: repeat each Parameter) {
        task?.cancel()
        
        task = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await action(repeat each parameter)
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}
