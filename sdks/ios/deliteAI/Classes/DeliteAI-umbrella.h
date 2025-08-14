/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "sources/impl/controller/NimbleNetController.h"
#import "sources/impl/controller/interactor/FunctionPointersImpl.h"
#import "sources/impl/controller/converter/InputConverter.h"
#import "sources/impl/controller/converter/OutputConverter.h"
#import "sources/impl/common/util/errorUtili/ErrorUtility.h"

FOUNDATION_EXPORT double DeliteAIVersionNumber;
FOUNDATION_EXPORT const unsigned char DeliteAIVersionString[];
