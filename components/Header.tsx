'use client'

import React from 'react'
import Link from 'next/link'
import { cn } from '@/lib/utils'  // If you're using this utility, make sure it's imported correctly
import { ModeToggle } from './ThemeToggle'

const Header = () => {
  return (
    <header className={cn('w-full z-50 top-0 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/95 dark:bg-background/95 dark:border-background/20 dark:supports-[backdrop-filter]:bg-background/60')}>
      <div className="container">
        <div className="flex items-center justify-between h-14 px-4">
          <Link href="/" className="text-lg font-semibold">
            Softex AI
          </Link>
          <div className='boder-l  pl-4 dark:border-gray-800'>
          <ModeToggle />

          </div>
        </div>
      </div>
    </header>
  )
}

export default Header
