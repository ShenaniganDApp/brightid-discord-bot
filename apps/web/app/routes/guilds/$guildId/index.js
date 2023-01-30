import GuildIdIndex_Res, {
  loader,
  action,
} from '~/res-routes/guilds/Guilds_Index.js'

export default props => {
  return <GuildIdIndex_Res {...props} />
}

export { loader, action }
