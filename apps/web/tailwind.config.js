const { fontFamily } = require('tailwindcss/defaultTheme')
const plugin = require('tailwindcss/plugin')

module.exports = {
  content: ['./app/**/*.{js,jsx,res}'],
  theme: {
    fontFamily: {
      poppins: ['Poppins', ...fontFamily.sans],
    },
    extend: {
      backgroundImage: {
        discordLogo: "url('/assets/discord_logo.png')",
      },
      colors: {
        primary: {
          400: '#00E0F3',
          500: '#00c4fd',
        },
        dark: '#333333',
        extraDark: '#1d1d1d',
        brightid: '#ed7a5c',
        disabled: '#fff0ed',
        discord: '#5865f2',
      },
      animation: {
        'text-scroll': 'bg 25s linear infinite',
      },
    },
  },
  variants: {
    width: ['responsive'],
  },

  plugins: [],
}
