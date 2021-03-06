-- Forward declaration
local Logger

-- ///////////////////////////////////////////////////////////////////////
-- Logger interface

Logger = Class.new()

Logger.LOG_LEVEL_NONE = 0
Logger.LOG_LEVEL_CONSOLE = 1
Logger.LOG_LEVEL_FILE = 2

function Logger:new(loggerImplClass)
	assert(loggerImplClass, "Argument #1 must not be nil")
	self:__init(loggerImplClass())
end

function Logger:__init(loggerImpl)
	self.getLoggingLevel = function(self)
		return loggerImpl:getLoggingLevel()
	end

	self.setLoggingLevel = function(self, level)
		loggerImpl:setLoggingLevel(level)
	end

	self.getLogFileName = function(self)
		return loggerImpl:getLogFileName()
	end

	self.setLogFileName = function(self, fileName)
		loggerImpl:setLogFileName(fileName)
	end

	self.getPrintCallerInfo = function(self)
		return loggerImpl:getPrintCallerInfo()
	end

	self.setPrintCallerInfo = function(self, printCallerInfo)
		loggerImpl:setPrintCallerInfo(printCallerInfo)
	end

	self.log = function(self, ...)
		loggerImpl:log(...)
	end
end

return Logger
