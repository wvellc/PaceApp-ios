//
//  typeAlias.swift
//  PaceApp
//
//  Created by FURKAN VIJAPURA on 4/1/26.
//

// A callback that takes no arguments and returns nothing
typealias VoidCallback = () -> Void

// A callback that takes no arguments and optionally returns nothing
typealias VoidOptionalCallback = () -> Void?

// A callback that takes one argument of type T and returns nothing
typealias Callback<T> = (T) -> Void

// A callback that takes one argument of type T and optionally returns nothing
typealias OptionalCallback<T> = (T) -> Void?

// A callback that takes no arguments and returns a value of type R
typealias Producer<R> = () -> R

// A callback that takes no arguments and optionally returns a value of type R
typealias OptionalProducer<R> = () -> R?

