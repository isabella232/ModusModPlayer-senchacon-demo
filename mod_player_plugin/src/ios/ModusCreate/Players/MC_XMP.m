//
//  MC_XMP.m
//  TicTacToe
//
//  Created by Jesus Garcia on 4/13/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MC_XMP.h"

@implementation MC_XMP


- (BOOL) loadFile:(NSString *)path  {
    if (self.xmpContext) {
        xmp_end_player(self.xmpContext);
        xmp_release_module(self.xmpContext);
        xmp_free_context(self.xmpContext);

    }

    char *filePath = [path UTF8String];

    self.xmpContext = xmp_create_context();
    struct xmp_module_info moduleInfo;
    
    int result = xmp_load_module(self.xmpContext, filePath);
    
    printf("LOAD RESULT = %i", result);
    
    
    result = xmp_start_player(self.xmpContext, 44100, 0);
    
    printf("START RESULT = %i", result);
    
    xmp_get_module_info(self.xmpContext, &moduleInfo);

    return 1;
}

- (void) fillBuffer:(AudioQueueBuffer *)mBuffer {

    xmp_play_buffer(self.xmpContext, mBuffer->mAudioData, mBuffer->mAudioDataByteSize, 100);

}


- (NSDictionary *)getInfo:(NSString *)path {

    char *filePath = [path UTF8String];
    
    int sample_rate = 44100; // number of samples per second


    xmp_context xmpContext = xmp_create_context();
    struct xmp_module_info moduleInfo;
    
    int result = xmp_load_module(xmpContext, filePath);
    
    printf("LOAD RESULT = %i", result);
    
    result = xmp_start_player(xmpContext, sample_rate, 0);
    
    printf("START RESULT = %i", result);
    
    xmp_get_module_info(xmpContext, &moduleInfo);
    
    
	struct xmp_module *mod = moduleInfo.mod;

	printf("\n");
//
//	printf("Instruments:\n");
//	for (i = 0; i < mod->ins; i++) {
//		struct xmp_instrument *ins = &mod->xxi[i];
//
//		printf("%02x %-32.32s V:%02x R:%04x %c%c%c\n",
//				i, ins->name, ins->vol, ins->rls,
//				ins->aei.flg & XMP_ENVELOPE_ON ? 'A' : '-',
//				ins->pei.flg & XMP_ENVELOPE_ON ? 'P' : '-',
//				ins->fei.flg & XMP_ENVELOPE_ON ? 'F' : '-'); 
//
//		for (j = 0; j < ins->nsm; j++) {
//			struct xmp_subinstrument *sub = &ins->sub[j];
//			printf("   %02x V:%02x GV:%02x P:%02x X:%+04d F:%+04d\n",
//					j, sub->vol, sub->gvl, sub->pan,
//					sub->xpo, sub->fin);
//		}
//	}
//
//	printf("\n");
//
//	printf("Samples:\n");
//	for (i = 0; i < mod->smp; i++) {
//		struct xmp_sample *smp = &mod->xxs[i];
//
//		printf("%02x %-32.32s %05x %05x %05x %c%c%c%c%c%c",
//				i, smp->name, smp->len, smp->lps, smp->lpe,
//				smp->flg & XMP_SAMPLE_16BIT ? 'W' : '-',
//				smp->flg & XMP_SAMPLE_LOOP ? 'L' : '-',
//				smp->flg & XMP_SAMPLE_LOOP_BIDIR ? 'B' : '-',
//				smp->flg & XMP_SAMPLE_LOOP_REVERSE ? 'R' : '-',
//				smp->flg & XMP_SAMPLE_LOOP_FULL ? 'F' : '-',
//				smp->flg & XMP_SAMPLE_SYNTH ? 'S' : '-');
//
//		if (smp->len > 0 && smp->lpe >= smp->len) {
//			printf(" LOOP ERROR");
//		}
//
//		printf("\n");
//	}
//
    xmp_end_player(xmpContext);
    xmp_release_module(xmpContext);
    xmp_free_context(xmpContext);
    return @{
        
        @"name"        : [[NSString alloc] initWithUTF8String:mod->name],
        @"type"        : [[NSString alloc] initWithUTF8String:mod->type],
        @"patterns"    : [[NSNumber alloc] initWithInt:mod->pat],
        @"tracks"      : [[NSNumber alloc] initWithInt:mod->trk],
        @"instruments" : [[NSNumber alloc] initWithInt:mod->ins],
        @"samples"     : [[NSNumber alloc] initWithInt:mod->smp],
        @"speed"       : [[NSNumber alloc] initWithInt:mod->spd],
        @"bpm"         : [[NSNumber alloc] initWithInt:mod->bpm],
        @"length"      : [[NSNumber alloc] initWithInt:mod->len],
        
    };
    
}

@end
